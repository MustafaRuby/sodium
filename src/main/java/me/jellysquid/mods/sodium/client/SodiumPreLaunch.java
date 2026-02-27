package me.jellysquid.mods.sodium.client;

import net.caffeinemc.mods.sodium.client.compatibility.checks.PreLaunchChecks;
import net.caffeinemc.mods.sodium.client.compatibility.environment.probe.GraphicsAdapterProbe;
import net.caffeinemc.mods.sodium.client.compatibility.workarounds.Workarounds;

/**
 * Performs pre-launch initialization tasks for Sodium on Forge.
 * On Forge, this is invoked early via the Mixin plugin or mod constructor
 * rather than through a Fabric entrypoint.
 */
public class SodiumPreLaunch {
    private static boolean initialized = false;

    public static void onPreLaunch() {
        if (initialized) {
            return;
        }
        initialized = true;

        PreLaunchChecks.checkEnvironment();
        GraphicsAdapterProbe.findAdapters();
        Workarounds.init();
    }
}
