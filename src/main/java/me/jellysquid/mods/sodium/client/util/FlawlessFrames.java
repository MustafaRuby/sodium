package me.jellysquid.mods.sodium.client.util;

import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;
import java.util.function.Function;

/**
 * Implements the "Flawless Frames" FREX feature using which third-party mods can instruct Sodium to sacrifice
 * performance (even beyond the point where it can no longer achieve interactive frame rates) in exchange for
 * a noticeable boost to quality.
 *
 * In Sodium's case, this means waiting for all chunks to be fully updated and ready for rendering before each frame.
 *
 * See https://github.com/grondag/frex/pull/9
 *
 * Note: On Forge, the FREX entrypoint system is not available. Third-party mods can interact with this
 * class directly via reflection or a provided API if needed.
 */
public class FlawlessFrames {
    private static final Set<Object> ACTIVE = Collections.newSetFromMap(new ConcurrentHashMap<>());

    public static void onClientInitialization() {
        // Forge does not have the Fabric entrypoint system for FREX flawless frames.
        // Third-party mods can call getProvider() to get a consumer for controlling this feature.
    }

    /**
     * Returns a provider function that creates per-caller activation tokens.
     * Third-party mods can use this to control flawless frames mode.
     */
    public static Function<String, Consumer<Boolean>> getProvider() {
        return name -> {
            Object token = new Object();
            return active -> {
                if (active) {
                    ACTIVE.add(token);
                } else {
                    ACTIVE.remove(token);
                }
            };
        };
    }

    public static boolean isActive() {
        return !ACTIVE.isEmpty();
    }
}
