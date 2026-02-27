package me.jellysquid.mods.sodium.mixin.features.render.world.sky;

import me.jellysquid.mods.sodium.client.util.color.FastCubicSampler;
import net.minecraft.client.renderer.FogRenderer;
import net.minecraft.client.Camera;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.util.CubicSampler;
import net.minecraft.util.Mth;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(FogRenderer.class)
public class BackgroundRendererMixin {
    @Redirect(method = "render", at = @At(value = "INVOKE", target = "Lnet/minecraft/util/CubicSampler;sampleColor(Lnet/minecraft/util/math/Vec3;Lnet/minecraft/util/CubicSampler$RgbFetcher;)Lnet/minecraft/util/math/Vec3;"))
    private static Vec3 redirectSampleColor(Vec3 pos, CubicSampler.RgbFetcher rgbFetcher, Camera camera, float tickDelta, ClientLevel world, int i, float f) {
        float u = Mth.clamp(Mth.cos(world.getSkyAngle(tickDelta) * 6.2831855F) * 2.0F + 0.5F, 0.0F, 1.0F);

        return FastCubicSampler.sampleColor(pos,
                (x, y, z) -> world.getBiomeAccess().getBiomeForNoiseGen(x, y, z).value().getFogColor(),
                (v) -> world.getDimensionEffects().adjustFogColor(v, u));
    }
}
