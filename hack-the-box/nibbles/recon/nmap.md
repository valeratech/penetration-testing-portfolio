# Nibbles — Reconnaissance · Network / Nmap

> A write-up for the **retired** Hack The Box machine *Nibbles*. Retired machines are approved for
> public publication under HTB's content-sharing rules.

> ℹ️ **Defanging note.** Lab IPs are HTB lab space (RFC 1918) and are defanged
> (`10.129.126.245` → `10[.]129[.]126[.]245`, `https://` → `hxxps://`) only for filter
> compatibility, not for safety. Commands reflect the live engagement exactly; only environmental
> identifiers are normalized. **Re-fang only in an authorized lab.** See
> [`SANITIZATION.md`](../../../SANITIZATION.md).

## Engagement context

- **Target:** `10[.]129[.]126[.]245` (ACADEMY-STARTING-OUT)
- **Approach:** grey-box — the target IP, its Linux OS, and a web-related vector are known in advance,
  so effort shifts from discovery toward enumeration and validation.
- **Tooling:** Nmap 7.95.

---

## Step 1 — Initial service / version scan

Begin with a service scan of the default top-1000 TCP ports, returning only open ports.

```bash
nmap -sV --open -oA nibbles_initial_scan 10[.]129[.]126[.]245
```

| Flag | Purpose |
|---|---|
| `-sV` | Service/version detection |
| `--open` | Show only open ports |
| `-oA` | Save output in all formats (`.nmap`, `.xml`, `.gnmap`) |

```
Starting Nmap 7.95 ( hxxps://nmap[.]org ) at 2026-07-26 13:46 EDT
Nmap scan report for 10[.]129[.]126[.]245
Host is up (0.14s latency).
Not shown: 984 closed tcp ports (conn-refused), 14 filtered tcp ports (no-response)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.2 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

**Finding:** Two open ports — **22/tcp (OpenSSH 7.2p2)** and **80/tcp (Apache httpd 2.4.18)** — on an
Ubuntu Linux host. The `OpenSSH 7.2p2` / `Apache 2.4.18` versions are consistent with the Ubuntu
16.04 ("Xenial") generation, though this remains an inference from banner versions, not a confirmed
release.

---

## Step 2 — Verify default Nmap port coverage

Running Nmap with no target prints the ports it *would* scan, confirming what the top-1000 default
covers (the scan itself fails, as no host is specified).

```bash
nmap -v -oG -
```

<details>
<summary><strong>Default top-1000 TCP port list (Nmap 7.95) — click to expand</strong></summary>

```
# Ports scanned: TCP(1000;1,3-4,6-7,9,13,17,19-26,30,32-33,37,42-43,49,53,70,79-85,88-90,99-100,106,109-111,113,119,125,135,139,143-144,146,161,163,179,199,211-212,222,254-256,259,264,280,301,306,311,340,366,389,406-407,416-417,425,427,443-445,458,464-465,481,497,500,512-515,524,541,543-545,548,554-555,563,587,593,616-617,625,631,636,646,648,666-668,683,687,691,700,705,711,714,720,722,726,749,765,777,783,787,800-801,808,843,873,880,888,898,900-903,911-912,981,987,990,992-993,995,999-1002,1007,1009-1011,1021-1100,1102,1104-1108,1110-1114,1117,1119,1121-1124,1126,1130-1132,1137-1138,1141,1145,1147-1149,1151-1152,1154,1163-1166,1169,1174-1175,1183,1185-1187,1192,1198-1199,1201,1213,1216-1218,1233-1234,1236,1244,1247-1248,1259,1271-1272,1277,1287,1296,1300-1301,1309-1311,1322,1328,1334,1352,1417,1433-1434,1443,1455,1461,1494,1500-1501,1503,1521,1524,1533,1556,1580,1583,1594,1600,1641,1658,1666,1687-1688,1700,1717-1721,1723,1755,1761,1782-1783,1801,1805,1812,1839-1840,1862-1864,1875,1900,1914,1935,1947,1971-1972,1974,1984,1998-2010,2013,2020-2022,2030,2033-2035,2038,2040-2043,2045-2049,2065,2068,2099-2100,2103,2105-2107,2111,2119,2121,2126,2135,2144,2160-2161,2170,2179,2190-2191,2196,2200,2222,2251,2260,2288,2301,2323,2366,2381-2383,2393-2394,2399,2401,2492,2500,2522,2525,2557,2601-2602,2604-2605,2607-2608,2638,2701-2702,2710,2717-2718,2725,2800,2809,2811,2869,2875,2909-2910,2920,2967-2968,2998,3000-3001,3003,3005-3006,3011,3017,3030-3031,3052,3071,3077,3128,3168,3211,3221,3260-3261,3268-3269,3283,3300-3301,3306,3322-3325,3333,3351,3367,3369-3372,3389-3390,3404,3476,3493,3517,3527,3546,3551,3580,3659,3689-3690,3703,3737,3766,3784,3800-3801,3809,3814,3826-3828,3851,3869,3871,3878,3880,3889,3905,3914,3918,3920,3945,3971,3986,3995,3998,4000-4006,4045,4111,4125-4126,4129,4224,4242,4279,4321,4343,4443-4446,4449,4550,4567,4662,4848,4899-4900,4998,5000-5004,5009,5030,5033,5050-5051,5054,5060-5061,5080,5087,5100-5102,5120,5190,5200,5214,5221-5222,5225-5226,5269,5280,5298,5357,5405,5414,5431-5432,5440,5500,5510,5544,5550,5555,5560,5566,5631,5633,5666,5678-5679,5718,5730,5800-5802,5810-5811,5815,5822,5825,5850,5859,5862,5877,5900-5904,5906-5907,5910-5911,5915,5922,5925,5950,5952,5959-5963,5985-5989,5998-6007,6009,6025,6059,6100-6101,6106,6112,6123,6129,6156,6346,6389,6502,6510,6543,6547,6565-6567,6580,6646,6666-6669,6689,6692,6699,6779,6788-6789,6792,6839,6881,6901,6969,7000-7002,7004,7007,7019,7025,7070,7100,7103,7106,7200-7201,7402,7435,7443,7496,7512,7625,7627,7676,7741,7777-7778,7800,7911,7920-7921,7937-7938,7999-8002,8007-8011,8021-8022,8031,8042,8045,8080-8090,8093,8099-8100,8180-8181,8192-8194,8200,8222,8254,8290-8292,8300,8333,8383,8400,8402,8443,8500,8600,8649,8651-8652,8654,8701,8800,8873,8888,8899,8994,9000-9003,9009-9011,9040,9050,9071,9080-9081,9090-9091,9099-9103,9110-9111,9200,9207,9220,9290,9415,9418,9485,9500,9502-9503,9535,9575,9593-9595,9618,9666,9876-9878,9898,9900,9917,9929,9943-9944,9968,9998-10004,10009-10010,10012,10024-10025,10082,10180,10215,10243,10566,10616-10617,10621,10626,10628-10629,10778,11110-11111,11967,12000,12174,12265,12345,13456,13722,13782-13783,14000,14238,14441-14442,15000,15002-15004,15660,15742,16000-16001,16012,16016,16018,16080,16113,16992-16993,17877,17988,18040,18101,18988,19101,19283,19315,19350,19780,19801,19842,20000,20005,20031,20221-20222,20828,21571,22939,23502,24444,24800,25734-25735,26214,27000,27352-27353,27355-27356,27715,28201,30000,30718,30951,31038,31337,32768-32785,33354,33899,34571-34573,35500,38292,40193,40911,41511,42510,44176,44442-44443,44501,45100,48080,49152-49161,49163,49165,49167,49175-49176,49400,49999-50003,50006,50300,50389,50500,50636,50800,51103,51493,52673,52822,52848,52869,54045,54328,55055-55056,55555,55600,56737-56738,57294,57797,58080,60020,60443,61532,61900,62078,63331,64623,64680,65000,65129,65389) UDP(0;) SCTP(0;) PROTOCOLS(0;)
```

</details>

**Finding:** The initial scan covered these 1,000 ports. A service on a non-standard port above this
range would be missed here — motivating the full TCP sweep in Step 3.

---

## Step 3 — Full TCP port scan

Scan all 65,535 TCP ports to confirm nothing is exposed on a non-standard port.

```bash
nmap -p- --open -oA nibbles_full_tcp_scan 10[.]129[.]126[.]245
```

```
Starting Nmap 7.95 ( hxxps://nmap[.]org ) at 2026-07-26 14:20 EDT
Nmap scan report for 10[.]129[.]126[.]245
Host is up (0.14s latency).
Not shown: 62341 closed tcp ports (conn-refused), 3192 filtered tcp ports (no-response)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
Nmap done: 1 IP address (1 host up) scanned in 52.47 seconds
```

**Finding:** No open ports beyond **22** and **80**. The full sweep closes off the possibility of a
service hiding on a high port — the attack surface is definitively SSH and HTTP.

---

## Step 4 — Manual banner validation (netcat)

Independently confirm Nmap's service detection by grabbing banners directly.

**Port 22 (SSH):**

```bash
nc -nv 10[.]129[.]126[.]245 22
```
```
Connection to 10[.]129[.]126[.]245 22 port [tcp/*] succeeded!
SSH-2.0-OpenSSH_7.2p2 Ubuntu-4ubuntu2.2
```

**Port 80 (HTTP):**

```bash
nc -nv 10[.]129[.]126[.]245 80
```
```
Connection to 10[.]129[.]126[.]245 80 port [tcp/*] succeeded!
```

**Finding:** The SSH banner (`OpenSSH_7.2p2 Ubuntu-4ubuntu2.2`) matches the `-sV` fingerprint exactly,
corroborating the version. HTTP returns no banner on a bare TCP connect — expected, since a web
server stays silent until it receives a request — confirming the port is open but requiring a
request-based tool to fingerprint it.

---

## Step 5 — Default NSE script scan

Run Nmap's default script set (`-sC`) against the two known ports.

```bash
nmap -sC -p 22,80 -oA nibbles_script_scan 10[.]129[.]126[.]245
```

```
Starting Nmap 7.95 ( hxxps://nmap[.]org ) at 2026-07-26 14:37 EDT
Nmap scan report for 10[.]129[.]126[.]245
Host is up (0.14s latency).
PORT   STATE SERVICE
22/tcp open  ssh
| ssh-hostkey:
|   2048 c4:f8:ad:e8:f8:04:77:de:cf:15:0d:63:0a:18:7e:49 (RSA)
|   256 22:8f:b1:97:bf:0f:17:08:fc:7e:2c:8f:e9:77:3a:48 (ECDSA)
|_  256 e6:ac:27:a3:b5:a9:f1:12:3c:34:a5:5d:5b:eb:3d:e9 (ED25519)
80/tcp open  http
|_http-title: Site doesn't have a title (text/html).
```

**Finding:** Nothing immediately actionable. The default scripts return the SSH host keys and confirm
the web root has no page title — no exposed configuration, redirects, or obvious application
fingerprints at this stage.

---

## Step 6 — HTTP NSE enumeration

Pair version detection with the `http-enum` script to probe for common web directories and resources.

```bash
nmap -sV --script=http-enum -oA nibbles_nmap_http_enum 10[.]129[.]126[.]245
```

```
Starting Nmap 7.95 ( hxxps://nmap[.]org ) at 2026-07-26 14:43 EDT
Nmap scan report for 10[.]129[.]126[.]245
Host is up (0.14s latency).
Not shown: 998 closed tcp ports (conn-refused)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.2 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

**Finding:** The `http-enum` script produced **no results** — it ran and identified no common
administrative paths, application directories, or publicly exposed resources (the only HTTP line,
`http-server-header`, comes from version detection, not `http-enum`). Automated HTTP enumeration
yielded nothing actionable, reinforcing the need for **manual inspection** of the web application.
The `http-server-header` independently re-confirms Apache 2.4.18.

---

## Reconnaissance summary

| Item | Result |
|---|---|
| **Open ports** | `22/tcp` (OpenSSH 7.2p2 Ubuntu 4ubuntu2.2), `80/tcp` (Apache httpd 2.4.18) |
| **Operating system** | Ubuntu Linux (banners consistent with the 16.04 generation — inference) |
| **Full TCP scan** | No additional open TCP ports |
| **SSH validation** | Manual banner confirmed the Nmap fingerprint |
| **Default NSE scripts** | SSH host keys collected; HTTP root has no title |
| **HTTP NSE enumeration** | No common web resources or administrative paths identified |

**Takeaway:** Automated network reconnaissance identified only SSH and HTTP, with no immediately
exploitable findings. With no additional services exposed and HTTP enumeration yielding little
information, the investigation naturally shifts toward **manual web-application footprinting**, where
the intended attack surface is expected to emerge.

---

**Defensive analysis:** detection opportunities from this reconnaissance phase — scanning
signatures, service enumeration artifacts, and network-layer indicators — are documented in
[`remediation.md`](../remediation.md) §3.1.
