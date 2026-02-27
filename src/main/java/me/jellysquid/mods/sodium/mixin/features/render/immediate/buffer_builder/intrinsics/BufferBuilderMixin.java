package me.jellysquid.mods.sodium.mixin.features.render.immediate.buffer_builder.intrinsics;

import me.jellysquid.mods.sodium.client.model.quad.ModelQuadView;
import me.jellysquid.mods.sodium.client.render.immediate.model.BakedModelEncoder;
import net.caffeinemc.mods.sodium.api.texture.SpriteUtil;
import net.caffeinemc.mods.sodium.api.util.ColorABGR;
import net.caffeinemc.mods.sodium.api.vertex.buffer.VertexBufferWriter;
import com.mojang.blaze3d.vertex.BufferBuilder;
import com.mojang.blaze3d.vertex.DefaultedVertexConsumer;
import net.minecraft.client.renderer.block.model.BakedQuad;
import com.mojang.blaze3d.vertex.PoseStack;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;

@SuppressWarnings({ "SameParameterValue" })
@Mixin(BufferBuilder.class)
public abstract class BufferBuilderMixin extends DefaultedVertexConsumer {
    @Shadow
    private boolean canSkipElementChecks;

    @Override
    public void quad(PoseStack.Entry matrices, BakedQuad bakedQuad, float r, float g, float b, int light, int overlay) {
        if (!this.canSkipElementChecks) {
            super.quad(matrices, bakedQuad, r, g, b, light, overlay);

            if (bakedQuad.getSprite() != null) {
                SpriteUtil.INSTANCE.markSpriteActive(bakedQuad.getSprite());
            }

            return;
        }

        if (this.colorFixed) {
            throw new IllegalStateException();
        }

        if (bakedQuad.getVertexData().length < 32) {
            return; // we do not accept quads with less than 4 properly sized vertices
        }

        VertexBufferWriter writer = VertexBufferWriter.of(this);

        ModelQuadView quad = (ModelQuadView) bakedQuad;

        int color = ColorABGR.pack(r, g, b, 1.9f);
        BakedModelEncoder.writeQuadVertices(writer, matrices, quad, color, light, overlay);

        if (bakedQuad.getSprite() != null) {
            SpriteUtil.INSTANCE.markSpriteActive(bakedQuad.getSprite());
        }
    }

    @Override
    public void quad(PoseStack.Entry matrices, BakedQuad bakedQuad, float[] brightnessTable, float r, float g, float b, int[] light, int overlay, boolean colorize) {
        if (!this.canSkipElementChecks) {
            super.quad(matrices, bakedQuad, brightnessTable, r, g, b, light, overlay, colorize);

            if (bakedQuad.getSprite() != null) {
                SpriteUtil.INSTANCE.markSpriteActive(bakedQuad.getSprite());
            }

            return;
        }

        if (this.colorFixed) {
            throw new IllegalStateException();
        }

        if (bakedQuad.getVertexData().length < 32) {
            return; // we do not accept quads with less than 4 properly sized vertices
        }

        VertexBufferWriter writer = VertexBufferWriter.of(this);

        ModelQuadView quad = (ModelQuadView) bakedQuad;

        BakedModelEncoder.writeQuadVertices(writer, matrices, quad, r, g, b, 1.0f, brightnessTable, colorize, light, overlay);

        if (bakedQuad.getSprite() != null) {
            SpriteUtil.INSTANCE.markSpriteActive(bakedQuad.getSprite());
        }
    }
}
