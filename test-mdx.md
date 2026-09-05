---
title: MDX fixture
description: Component tags, expressions, and imports the raw-scope rules must read past
---

import { Callout, Tabs, Tab } from "@site/components";
import Image from "next/image";

export const meta = { owner: "docs" };

# Install guide

<Callout type="info">
Each install writes a config file next to the binary.
</Callout>

<Callout type="warning">
Older shells need a restart before the path change applies.
</Callout>

<Callout type="tip">
Run the doctor command after the first install.
</Callout>

<Tabs>
<Tab title="macOS">
Homebrew installs the signed build.
</Tab>
<Tab title="Linux">
A tarball unpacks into a single directory.
</Tab>
<Tab title="Windows">
Windows installs register the path for every user.
</Tab>
</Tabs>

{/* This comment explains the image below. */}

<Image src="/img/doctor.png" alt="The doctor output" width={600} height={300} />

The doctor command checks the path, the config file, and the cache directory. It prints one line per check. A failed check names the fix. You can rerun it at any time.

<Callout type="info">
Upgrades keep the config file.
</Callout>

<Callout type="info">
Downgrades keep it too.
</Callout>

<Callout type="info">
Uninstalling removes it.
</Callout>
