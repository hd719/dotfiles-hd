# Chezmoi Migration

This language separates disposable proof from changes to Hamel's real machines.

## Language

**Source state**:
The reviewed, canonical user configuration that chezmoi can render for a
specific profile.
_Avoid_: Live dotfiles, home-directory source

**Target state**:
The user files rendered on a particular machine from the source state.
_Avoid_: Source files

**User environment**:
Declarative user files and profile-scoped package manifests. It excludes
lifecycle, services, secrets, identity, and mutable runtime state.
_Avoid_: Whole machine

**Profile**:
A named set of user-environment policy for Ubuntu, the thin Mac, the Mac mini,
or the work Mac.
_Avoid_: Machine when referring to policy

**Canary**:
A disposable VM used to prove a profile without personal credentials,
production connections, or durable state.
_Avoid_: Test production host

**Production host**:
A real machine whose user environment affects Hamel's normal work or running
services.
_Avoid_: Canary

**Ownership transfer**:
The point when one managed path stops belonging to the current bootstrap and
starts belonging to chezmoi.
_Avoid_: Dual management

**Machine-owned state**:
Identity, authentication, secrets, histories, enrollment, and mutable
application or runtime data that chezmoi must not render.
_Avoid_: Dotfiles

**Lifecycle-owned state**:
VM, system, service, and recurring maintenance behavior that remains with
Vagrant, Ansible, or the existing maintenance commands.
_Avoid_: User environment

**Promotion**:
Hamel's explicit approval to move from a proven stage to the next host.
_Avoid_: Automatic rollout

**Soak**:
A period of normal use after cutover during which Hamel judges stability before
any promotion.
_Avoid_: Automatic timeout

**Legacy bootstrap**:
The preserved former setup implementation after every approved host has
completed migration.
_Avoid_: Deleted bootstrap, active second writer
