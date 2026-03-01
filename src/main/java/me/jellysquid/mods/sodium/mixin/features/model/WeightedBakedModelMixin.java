package me.jellysquid.mods.sodium.mixin.features.model;

import net.minecraft.client.renderer.RenderType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.client.renderer.block.model.BakedQuad;
import net.minecraft.client.resources.model.WeightedBakedModel;
import net.minecraft.util.random.WeightedEntry;
import net.minecraft.core.Direction;
import net.minecraft.util.RandomSource;
import net.minecraftforge.client.model.data.ModelData;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.spongepowered.asm.mixin.*;

import java.util.*;

@Mixin(WeightedBakedModel.class)
public class WeightedBakedModelMixin {
    @Shadow
    @Final
    private List<WeightedEntry.Wrapper<BakedModel>> list;

    @Shadow
    @Final
    private int totalWeight;

    /**
     * @author JellySquid
     * @reason Avoid excessive object allocations
     */
    @Overwrite(remap = false)
    public @NotNull List<BakedQuad> getQuads(@Nullable BlockState state, @Nullable Direction face, @NotNull RandomSource random, @NotNull ModelData modelData, @Nullable RenderType renderType) {
        WeightedEntry.Wrapper<BakedModel> quad = getAt(this.list, Math.abs((int) random.nextLong()) % this.totalWeight);

        if (quad != null) {
            return quad.getData()
                    .getQuads(state, face, random, modelData, renderType);
        }

        return Collections.emptyList();
    }

    @Unique
    private static <T extends WeightedEntry> T getAt(List<T> pool, int totalWeight) {
        int i = 0;
        int len = pool.size();

        T weighted;

        do {
            if (i >= len) {
                return null;
            }

            weighted = pool.get(i++);
            totalWeight -= weighted.getWeight().asInt();
        } while (totalWeight >= 0);

        return weighted;
    }
}
