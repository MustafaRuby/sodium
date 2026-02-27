package me.jellysquid.mods.sodium.mixin.core.render;

import it.unimi.dsi.fastutil.ints.IntList;
import com.mojang.blaze3d.vertex.VertexFormat;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(VertexFormat.class)
public interface VertexFormatAccessor {
    @Accessor
    IntList getOffsets();
}
