#!/usr/bin/env node
// ORKYN : lanceur stdio du serveur MCP IMAP (@ni-c/imap-mcp) pour l'agent orkyn-inbox. macOS, Linux et Windows.
// Usage : node mail-mcp.mjs [--print-env]
//  - lancé par Claude Code (stdout = protocole MCP, rien d'autre), configuré par ORKYN_MAIL_* (userConfig du plugin).
//  - --print-env : affiche la configuration résolue SANS le mot de passe et ne lance rien (essai à blanc).
//  - configuration en LECTURE SEULE : seuls list_mailboxes, list_messages et get_message sont exposés.
//  - un seul compte par processus.
// Paquet épinglé : version 0.6.0, provenance SLSA vérifiée, tag v0.6.0, commit b65be1d.
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

const PKG = "@ni-c/imap-mcp@0.6.0";
const ALLOW = "list_mailboxes,list_messages,get_message";
const DENY = "list_new_messages,get_server_info,delete_messages,manage_mailbox,move_messages,save_draft,set_message_flags";

const die = (msg) => { process.stderr.write(`ORKYN : ${msg}\n`); process.exit(1); };
const env = process.env;
const ALLOWED = ALLOW.split(",");

// Configuration absente ou invalide : au lieu de mourir (Claude Code n'afficherait qu'un échec de connexion),
// on sert un MCP minimal qui expose les mêmes outils et renvoie le message à chaque appel.
// Avec --print-env, on garde l'arrêt avec code d'erreur.
const fail = (msg) => {
  if (process.argv.includes("--print-env")) die(msg);
  process.stderr.write(`ORKYN : ${msg}\n`);
  const text = `ORKYN : ${msg}`;
  const send = (o) => process.stdout.write(JSON.stringify(o) + "\n");
  let buf = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => {
    buf += chunk;
    let i;
    while ((i = buf.indexOf("\n")) >= 0) {
      const line = buf.slice(0, i).trim();
      buf = buf.slice(i + 1);
      if (!line) continue;
      let req;
      try { req = JSON.parse(line); } catch { continue; }
      if (req.id === undefined || req.id === null) continue;
      const ok = (result) => send({ jsonrpc: "2.0", id: req.id, result });
      if (req.method === "initialize") {
        ok({
          protocolVersion: req.params?.protocolVersion || "2025-06-18",
          capabilities: { tools: {} },
          serverInfo: { name: "orkyn-mail (non configuré)", version: "0" },
          instructions: text,
        });
      } else if (req.method === "tools/list") {
        ok({ tools: ALLOWED.map((name) => ({ name, description: text, inputSchema: { type: "object", properties: {} } })) });
      } else if (req.method === "tools/call") {
        ok({ content: [{ type: "text", text }], isError: true });
      } else if (req.method === "ping") {
        ok({});
      } else {
        send({ jsonrpc: "2.0", id: req.id, error: { code: -32601, message: "méthode non prise en charge" } });
      }
    }
  });
  process.stdin.on("end", () => process.exit(0));
};

const main = () => {

  const provider = env.ORKYN_MAIL_PROVIDER || "none";
  const addr = env.ORKYN_MAIL_ADDRESS || "";
  const pass = env.ORKYN_MAIL_PASSWORD || "";

  if (provider === "none") {
    return fail("mails non configurés. Tapez /plugin configure orkyn@orkyn et choisissez votre fournisseur, votre adresse et un mot de passe d'application.");
  }
  if (!addr || !pass) return fail("adresse mail ou mot de passe manquant dans la configuration du plugin orkyn.");
  if (/\s/.test(addr) || !addr.includes("@")) return fail("adresse mail invalide.");

  const PROVIDERS = {
    gmail: ["imap.gmail.com", "993", "implicit"],
    icloud: ["imap.mail.me.com", "993", "implicit"],
    yahoo: ["imap.mail.yahoo.com", "993", "implicit"],
    proton: ["127.0.0.1", "1143", "starttls"],
    fastmail: ["imap.fastmail.com", "993", "implicit"],
    zoho: ["imap.zoho.com", "993", "implicit"],
    gmx: ["imap.gmx.net", "993", "implicit"],
    free: ["imap.free.fr", "993", "implicit"],
    laposte: ["imap.laposte.net", "993", "implicit"],
    ovh: ["ssl0.ovh.net", "993", "implicit"],
    ionos: ["imap.ionos.com", "993", "implicit"],
    orange: ["imap.orange.fr", "993", "implicit"],
    sfr: ["imap.sfr.fr", "993", "implicit"],
  };

  let host, port, tls;
  if (provider === "autre") {
    host = env.ORKYN_MAIL_HOST || "";
    port = env.ORKYN_MAIL_PORT || "993";
    const sec = env.ORKYN_MAIL_SECURITY || "tls";
    if (sec === "tls" || sec === "implicit") tls = "implicit";
    else if (sec === "starttls") tls = "starttls";
    else return fail("sécurité invalide (valeurs : tls, starttls).");
    if (!host) return fail("fournisseur « autre » : renseignez le serveur IMAP.");
    if (!/^[A-Za-z0-9.-]+$/.test(host)) return fail("nom de serveur IMAP invalide.");
    if (!/^[0-9]{1,5}$/.test(port)) return fail("port IMAP invalide.");
  } else if (PROVIDERS[provider]) {
    [host, port, tls] = PROVIDERS[provider];
  } else {
    return fail(`fournisseur inconnu : ${provider}.`);
  }
  const insecure = host === "127.0.0.1" ? "true" : "false";

  if (process.argv.includes("--print-env")) {
    process.stdout.write([
      `fournisseur=${provider}`, `IMAP_HOST=${host}`, `IMAP_PORT=${port}`, `IMAP_TLS=${tls}`,
      `IMAP_INSECURE_TLS=${insecure}`, `IMAP_USER=${addr}`, "IMAP_PASSWORD=(défini, masqué)",
      "IMAP_READ_ONLY=true", "IMAP_SEEN_KEYWORD=", `IMAP_ALLOW_TOOLS=${ALLOW}`, `IMAP_DENY_TOOLS=${DENY}`,
      `paquet=${PKG}`, "",
    ].join("\n"));
    process.exit(0);
  }

  const major = Number(process.versions.node.split(".")[0]);
  if (!(major >= 24)) return fail(`Node 24 ou plus requis (version détectée : ${process.versions.node}).`);

  const childEnv = { ...env };
  for (const k of ["IMAP_DOWNLOAD_DIR", "IMAP_ALLOW_WRITE", "ORKYN_MAIL_PASSWORD"]) delete childEnv[k];
  Object.assign(childEnv, {
    IMAP_HOST: host, IMAP_PORT: port, IMAP_TLS: tls, IMAP_INSECURE_TLS: insecure,
    IMAP_USER: addr, IMAP_PASSWORD: pass,
    IMAP_READ_ONLY: "true", IMAP_SEEN_KEYWORD: "",
    IMAP_ALLOW_TOOLS: ALLOW, IMAP_DENY_TOOLS: DENY,
  });

  // npx lancé via le node courant quand c'est possible (évite les soucis de npx.cmd sous Windows).
  const nodeDir = dirname(process.execPath);
  const npxCli = [
    join(nodeDir, "node_modules", "npm", "bin", "npx-cli.js"),
    join(nodeDir, "..", "lib", "node_modules", "npm", "bin", "npx-cli.js"),
  ].find(existsSync);

  const child = npxCli
    ? spawn(process.execPath, [npxCli, "-y", PKG], { stdio: "inherit", env: childEnv })
    : spawn("npx", ["-y", PKG], { stdio: "inherit", env: childEnv, shell: process.platform === "win32" });

  child.on("error", (e) => die(`impossible de lancer npx (${e.code || e.message}).`));
  child.on("exit", (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
  for (const sig of ["SIGINT", "SIGTERM"]) process.on(sig, () => child.kill(sig));
};

main();
