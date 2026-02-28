package me.jellysquid.mods.sodium.mixin.features.options.render_layers;

import me.jellysquid.mods.sodium.client.SodiumClientMod;
import net.minecraft.world.level.block.*;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.client.Minecraft;
import net.minecraft.core.Direction;
import org.spongepowered.asm.mixin.Mixin;

@Mixin(LeavesBlock.class)
public class LeavesBlockMixin extends Block {
    public LeavesBlockMixin() {
        super(BlockBehaviour.Properties.copy(Blocks.AIR));
        throw new AssertionError("Mixin constructor called!");
    }

    @Override
    public boolean skipRendering(BlockState state, BlockState stateFrom, Direction direction) {
        if (SodiumClientMod.options().quality.leavesQuality.isFancy(Minecraft.getInstance().options.graphicsMode().get())) {
            return super.skipRendering(state, stateFrom, direction);
        } else {
            return stateFrom.getBlock() instanceof LeavesBlock || super.skipRendering(state, stateFrom, direction);
        }
    }
}
