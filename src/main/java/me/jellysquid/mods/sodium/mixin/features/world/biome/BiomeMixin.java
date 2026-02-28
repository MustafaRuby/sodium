package me.jellysquid.mods.sodium.mixin.features.world.biome;

import me.jellysquid.mods.sodium.client.world.biome.BiomeColorMaps;
import net.minecraft.util.Mth;
import net.minecraft.world.level.biome.Biome;
import net.minecraft.world.level.biome.BiomeSpecialEffects;
import org.spongepowered.asm.mixin.*;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Biome.class)
public abstract class BiomeMixin {
    @Shadow
    @Final
    private BiomeSpecialEffects effects;

    @Shadow
    @Final
    private Biome.ClimateSettings weather;

    @Unique
    private boolean hasCustomGrassColor;

    @Unique
    private int customGrassColor;

    @Unique
    private boolean hasCustomFoliageColor;

    @Unique
    private int customFoliageColor;

    @Unique
    private int defaultColorIndex;

    @Unique
    private BiomeSpecialEffects cachedSpecialEffects;

    @Inject(method = "<init>", at = @At("RETURN"))
    private void onInit(CallbackInfo ci) {
        setupColors();
    }

    @Unique
    private void setupColors() {
        this.cachedSpecialEffects = effects;

        var grassColor = this.effects.getGrassColorOverride();

        if (grassColor.isPresent()) {
            this.hasCustomGrassColor = true;
            this.customGrassColor = grassColor.get();
        }

        var foliageColor = this.effects.getFoliageColorOverride();

        if (foliageColor.isPresent()) {
            this.hasCustomFoliageColor = true;
            this.customFoliageColor = foliageColor.get();
        }

        this.defaultColorIndex = this.getDefaultColorIndex();
    }

    /**
     * @author JellySquid
     * @reason Avoid unnecessary pointer de-references and allocations
     */
    @Overwrite
    public int getGrassColor(double x, double z) {
        if (this.effects != this.cachedSpecialEffects) {
            setupColors();
        }

        int color;

        if (this.hasCustomGrassColor) {
            color = this.customGrassColor;
        } else {
            color = BiomeColorMaps.getGrassColor(this.defaultColorIndex);
        }

        var modifier = this.effects.getGrassColorModifier();

        if (modifier != BiomeSpecialEffects.GrassColorModifier.NONE) {
            color = modifier.modifyColor(x, z, color);
        }

        return color;
    }

    /**
     * @author JellySquid
     * @reason Avoid unnecessary pointer de-references and allocations
     */
    @Overwrite
    public int getFoliageColor() {
        if (this.effects != this.cachedSpecialEffects) {
            setupColors();
        }

        int color;

        if (this.hasCustomFoliageColor) {
            color = this.customFoliageColor;
        } else {
            color = BiomeColorMaps.getFoliageColor(this.defaultColorIndex);
        }

        return color;
    }

    @Unique
    private int getDefaultColorIndex() {
        double temperature = Mth.clamp(this.weather.temperature(), 0.0F, 1.0F);
        double humidity = Mth.clamp(this.weather.downfall(), 0.0F, 1.0F);

        return BiomeColorMaps.getIndex(temperature, humidity);
    }
}
