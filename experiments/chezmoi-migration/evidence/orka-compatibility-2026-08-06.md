# Orka Compatibility Evidence

Date: 2026-08-06

Ticket: [Validate Orka Desktop on the thin Mac](https://github.com/hd719/dotfiles-hd/issues/83)

Result: pass, with a resource-sizing recommendation and one deferred destructive
test.

## Environment

- Thin host: Apple M3 Max, 36 GB memory, macOS 26.6.
- Orka Desktop: `3.1.0-c52b0580`, signed by MacStadium Inc.
- Disposable guest: `chezmoi-test`, macOS 26.6, ARM64.
- Guest allocation during validation: 12 vCPUs, 28 GB memory, 150 GB disk.

No password, credential, token, or personal account information is recorded.

## Checks

| Check                                              | Result |
| -------------------------------------------------- | ------ |
| Orka launches on the macOS 26.6 thin host          | Pass   |
| Existing disposable guest boots                    | Pass   |
| Guest resolves over local mDNS                     | Pass   |
| SSH port is reachable                              | Pass   |
| SSH login with the test account succeeds           | Pass   |
| Network and outbound HTTPS work                    | Pass   |
| Guest reports macOS 26.6 on ARM64                  | Pass   |
| Scanned and guest-reported Ed25519 host keys match | Pass   |
| Orka stop closes guest SSH                         | Pass   |
| Orka restart restores SSH and the same host key    | Pass   |
| Vagrant still reports the Ubuntu VM as powered off | Pass   |
| VMware provider remains installed at `3.0.5`       | Pass   |

Verified guest host-key fingerprint:

```text
SHA256:tTOgvYeGdzemKTegY3ALekMDGHAfX1K9aPh1idJHUHc
```

## Safety Findings

- The Ubuntu VM stayed powered off throughout the Orka test.
- VMware Fusion remained open and the supported Vagrant status command kept
  working.
- No production host, service, credential, Tailscale identity, or dotfile was
  changed.
- The guest's initial creation and setup were completed manually by Hamel.

## Follow-up

Before sustained chezmoi testing, reduce the guest to approximately 8 vCPUs and
16 GB memory. The validated 28 GB allocation caused unnecessary host memory
compression and leaves too little room for the thin-Mac control plane.

The destructive erase-and-recreate test was intentionally deferred. Perform it
only after the thin-profile canary evidence is accepted and immediately before
reusing this same VM for the Mac mini profile.
