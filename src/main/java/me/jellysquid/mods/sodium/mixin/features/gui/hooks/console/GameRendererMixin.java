package me.jellysquid.mods.sodium.mixin.features.gui.hooks.console;


import me.jellysquid.mods.sodium.client.gui.console.ConsoleHooks;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.renderer.RenderBuffers;
import net.minecraft.client.renderer.GameRenderer;
import org.lwjgl.glfw.GLFW;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.Unique;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(GameRenderer.class)
public class GameRendererMixin {
    @Shadow
    @Final
    Minecraft client;

    @Shadow
    @Final
    private RenderBuffers buffers;

    @Unique
    private static boolean HAS_RENDERED_OVERLAY_ONCE = false;

    @Inject(method = "render", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/gui/GuiGraphics;draw()V", shift = At.Shift.AFTER))
    private void onRender(float tickDelta, long startTime, boolean tick, CallbackInfo ci) {
        // Do not start updating the console overlay until the font renderer is ready
        // This prevents the console from using tofu boxes for everything during early startup
        if (Minecraft.getInstance().getOverlay() != null) {
            if (!HAS_RENDERED_OVERLAY_ONCE) {
                return;
            }
        }

        this.client.getProfiler()
                .push("sodium_console_overlay");

        GuiGraphics drawContext = new GuiGraphics(this.client, this.buffers.getEntityVertexMultiConsumer());

        ConsoleHooks.render(drawContext, GLFW.glfwGetTime());

        drawContext.draw();

        this.client.getProfiler()
                .pop();

        HAS_RENDERED_OVERLAY_ONCE = true;
    }
}
