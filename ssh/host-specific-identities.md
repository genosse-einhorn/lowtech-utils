Separate SSH identities for multiple hosts
==========================================

Add this to your `~/.ssh/config`

    IdentityFile ~/.ssh/identities/%h

Now you can have per-host identities neatly organized in a folder.
You can even use symlinks for grouping!

Generate your identity using

    ssh-keygen -t ed25519 -o -a 100 -f ~/.ssh/identities/$host

And transfer it using

    ssh-copy-id -i ~/.ssh/identities/$host $user@$host

No need to mess with the agent or `ssh-ident` in simple setups.
