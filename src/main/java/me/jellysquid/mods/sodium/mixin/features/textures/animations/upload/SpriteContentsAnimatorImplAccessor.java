package me.jellysquid.mods.sodium.mixin.features.textures.animations.upload;

import net.minecraft.client.renderer.texture.SpriteContents;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(SpriteContents.Ticker.class)
public interface SpriteContentsAnimatorImplAccessor {
    @Accessor("animationInfo")
    SpriteContents.AnimatedTexture getAnimation();

    @Accessor("frame")
    int getFrameIndex();

    @Accessor("subFrame")
    int getFrameTicks();
}
