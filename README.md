# tp-arm64-busybox — Linux embarqué ARM64

Distribution Linux minimale pour **ARM64 (aarch64)**, construite *from scratch* (sans Buildroot ni Yocto) à partir des sources officielles : noyau Linux, BusyBox et PHP. Elle est validée dans **QEMU**, puis portée sur **Raspberry Pi**.

## Environnement de build

| Élément | Choix |
|---|---|
| Machine de build | VM Debian 13 (x86_64) sous VMware, 4 vCPU / 3 Go RAM |
| Compilateur croisé | `gcc-aarch64-linux-gnu` 14.2 (paquet Debian, version figée par apt) |
| Noyau | Linux 6.12 (LTS) — kernel.org |
| BusyBox | 1.36.1 — busybox.net |
| Émulateur | QEMU 10 (`qemu-system-aarch64`, machine `virt`, CPU Cortex-A53) |

Les versions sont centralisées dans `scripts/env.sh`. Les archives sont vérifiées par **SHA-256** et les fichiers `.config` sont sauvegardés dans `configs/` : relancer les scripts reproduit exactement le même système.

## Arborescence du dépôt

```
scripts/
  env.sh              variables communes (versions, chemins, toolchain)
  00-install-deps.sh  installe la toolchain croisée et QEMU
  01-kernel.sh        télécharge, vérifie, configure et compile le noyau -> out/Image
  02-busybox.sh       compile BusyBox en statique
  03-rootfs.sh        construit l'arborescence de la cible (rootfs/)
  04-initramfs.sh     génère out/initramfs.cpio.gz
  05-qemu.sh          démarre le système dans QEMU
files/init            script de démarrage (PID 1)
configs/              configurations noyau et BusyBox sauvegardées
```

`dl/`, `build/`, `rootfs/` et `out/` sont générés et exclus du dépôt (`.gitignore`).

## Utilisation

```bash
./scripts/00-install-deps.sh
./scripts/01-kernel.sh      # ~1 h sur 4 cœurs
./scripts/02-busybox.sh
./scripts/03-rootfs.sh
./scripts/04-initramfs.sh
./scripts/05-qemu.sh        # quitter : Ctrl-A puis X
```

## Séquence de démarrage

```
QEMU (firmware virt)
  └─> charge le noyau out/Image + l'initramfs en RAM
        └─> noyau Linux arm64
              ├─ initialise CPU, mémoire, console série PL011 (ttyAMA0)
              ├─ décompresse initramfs.cpio.gz dans un rootfs en RAM
              ├─ ouvre /dev/console (créé dans l'archive)
              └─> exécute /init (rdinit=/init) = PID 1
                    ├─ monte /proc, /sys, /dev (devtmpfs), /dev/pts
                    ├─ monte /tmp et /run en tmpfs (nosuid, nodev)
                    ├─ hostname, journal de boot -> /var/log/boot.log
                    └─> boucle : shell BusyBox sur la console série
```

1. **QEMU** simule une carte ARM64 générique (`-M virt`) et place en mémoire le noyau (`-kernel`) et l'initramfs (`-initrd`). La ligne de commande noyau `console=ttyAMA0 rdinit=/init` indique la console série et le programme à lancer.
2. **Le noyau** démarre, détecte le matériel virtuel (UART PL011, périphériques VirtIO) puis décompresse l'archive `cpio` en un système de fichiers en RAM (`rootfs`).
3. **`/init`** est le premier processus (PID 1). Il monte les systèmes de fichiers virtuels, puis lance un shell BusyBox via `setsid cttyhack` pour avoir un vrai terminal de contrôle (Ctrl-C fonctionnel).
4. **PID 1 ne doit jamais se terminer** : sinon, le noyau déclenche un *Kernel Panic* (« Attempted to kill init »). Le shell est donc relancé en boucle si l'utilisateur tape `exit`.

## Choix techniques et sécurité

- **Noyau sans modules** (`CONFIG_MODULES=n`) : tout est intégré à l'image. Il n'y a pas de `/lib/modules` sur la cible et il est impossible de charger un module malveillant à chaud.
- **BusyBox statique et strippée** : aucune dépendance à une bibliothèque partagée (pas de `LD_PRELOAD` ni de détournement de libc possible). Un seul binaire d'environ 2 Mo fournit toutes les commandes.
- **Pas de gestionnaire de paquets sur la cible** : le système est figé à la compilation, ce qui réduit la surface d'attaque et rend toute modification visible.
- **`/tmp` et `/run` en `nosuid,nodev`** : un fichier déposé ne peut ni obtenir des droits root, ni servir de faux périphérique.
- **Archive initramfs construite avec `fakeroot`** : les fichiers appartiennent à `root:root` sans exécuter le build en root.
- **Intégrité des sources** : vérification SHA-256 des archives noyau et BusyBox avant compilation.

## Diagnostic

| Symptôme | Cause probable |
|---|---|
| `Kernel panic - not syncing: No working init found` | `/init` absent, non exécutable ou avec des fins de ligne CRLF |
| `Kernel panic ... Attempted to kill init` | le script `/init` s'est terminé |
| `unable to open an initial console` | `/dev/console` absent de l'initramfs |
| Aucun affichage | mauvaise console (`console=ttyAMA0` requis sur `virt`) |

Le journal de boot est consultable sur la cible : `cat /var/log/boot.log`.

## Avancement

- [x] Semaine 1 — toolchain, noyau arm64, BusyBox statique, `/init`, initramfs, boot QEMU
- [ ] Semaine 2 — réseau VirtIO, PHP-CGI statique, httpd BusyBox, accès depuis le réseau
- [ ] Semaine 3 — portage Raspberry Pi, DHCP (udhcpc)
