package me.jellysquid.mods.sodium.client.render.chunk.terrain;

import net.minecraft.client.renderer.RenderType;

public class DefaultTerrainRenderPasses {
    public static final TerrainRenderPass SOLID = new TerrainRenderPass(RenderType.getSolid(), false, false);
    public static final TerrainRenderPass CUTOUT = new TerrainRenderPass(RenderType.getCutoutMipped(), false, true);
    public static final TerrainRenderPass TRANSLUCENT = new TerrainRenderPass(RenderType.getTranslucent(), true, false);


    public static final TerrainRenderPass[] ALL = new TerrainRenderPass[] { SOLID, CUTOUT, TRANSLUCENT };
}
