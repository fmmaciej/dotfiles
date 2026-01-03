# rt - minimalny CLI wrapper dla rtorrent

`rt` to prosty wrapper CLI dla **rtorrent działającego jako daemon**.  
Sterowanie odbywa się przez **RPC (UNIX socket)** z użyciem **fzf** jako interfejsu wyboru.

Brak GUI. Brak TUI. Jeden binarek, jedno zadanie.

## Wymagania

- rtorrent
- xmlrpc-c (`xmlrpc`)
- fzf
- działający rtorrent z RPC socketem:

`~/.rtorrent/rpc.socket`

## Struktura katalogów

```bash
~/.rtorrent/
├── session/
├── watch/
└── rpc.socket
```

`~/downloads/torrents/`

## Użycie

### Dodanie torrenta

```bash
rt add file.torrent
```

Kopiuje plik `.torrent` do katalogu `watch/`.
rtorrent automatycznie rozpocznie pobieranie.

### Start torrentów

```bash
rt start
```

- otwiera fzf
- wybór jednego lub wielu torrentów
- Enter -> start

### Stop torrentów

```bash
rt stop
```

- wybór w fzf
- zatrzymuje wybrane torrenty

### Usunięcie torrentów

```bash
rt rm
```

- usuwa torrent i dane
- operacja nieodwracalna

### Widok fzf

Format listy:

```bash
HASH     | % | NAZWA
```

Przykład:

```bash
a1b2c3d4 | 87% | Ubuntu 24.04 ISO
```

- nawigacja: hjkl
- multi-select: Tab
- potwierdzenie: Enter

Uwagi
- `rt` zakłada lokalny socket RPC (bez TCP)
- brak stanu w kliencie - całość trzyma rtorrent
- skrypt nie modyfikuje konfiguracji rtorrenta

## Pomoc

```bash
rt
```

Wyświetla krótkie usage.

