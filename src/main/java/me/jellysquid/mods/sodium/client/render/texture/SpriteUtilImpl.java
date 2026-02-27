package me.jellysquid.mods.sodium.client.render.texture;

import net.caffeinemc.mods.sodium.api.texture.SpriteUtil;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import org.jetbrains.annotations.NotNull;

import java.util.Objects;

public class SpriteUtilImpl implements SpriteUtil {
    @Override
    public void markSpriteActive(@NotNull TextureAtlasSprite sprite) {
        Objects.requireNonNull(sprite);

        ((SpriteContentsExtended) sprite.contents()).sodium$setActive(true);
    }

    @Override
    public boolean hasAnimation(@NotNull TextureAtlasSprite sprite) {
        Objects.requireNonNull(sprite);

        return ((SpriteContentsExtended) sprite.contents()).sodium$hasAnimation();
    }
}