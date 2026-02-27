package me.jellysquid.mods.sodium.client.render.chunk.terrain.material;

import me.jellysquid.mods.sodium.client.render.chunk.terrain.DefaultTerrainRenderPasses;
import me.jellysquid.mods.sodium.client.render.chunk.terrain.material.parameters.AlphaCutoffParameter;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.world.level.material.FluidState;

public class DefaultMaterials {
    public static final Material SOLID = new Material(DefaultTerrainRenderPasses.SOLID, AlphaCutoffParameter.ZERO, true);
    public static final Material CUTOUT = new Material(DefaultTerrainRenderPasses.CUTOUT, AlphaCutoffParameter.ONE_TENTH, false);
    public static final Material CUTOUT_MIPPED = new Material(DefaultTerrainRenderPasses.CUTOUT, AlphaCutoffParameter.ONE_TENTH, true);
    public static final Material TRANSLUCENT = new Material(DefaultTerrainRenderPasses.TRANSLUCENT, AlphaCutoffParameter.ZERO, true);

    public static Material forBlockState(BlockState state) {
        return forRenderType(ItemBlockRenderTypes.getBlockLayer(state));
    }

    public static Material forFluidState(FluidState state) {
        return forRenderType(ItemBlockRenderTypes.getFluidLayer(state));
    }

    public static Material forRenderType(RenderType layer) {
        if (layer == RenderType.getSolid()) {
            return SOLID;
        } else if (layer == RenderType.getCutout()) {
            return CUTOUT;
        } else if (layer == RenderType.getCutoutMipped() || layer == RenderType.getTripwire()) {
            return CUTOUT_MIPPED;
        } else if (layer == RenderType.getTranslucent()) {
            return TRANSLUCENT;
        }

        throw new IllegalArgumentException("No material mapping exists for " + layer);
    }
}
