package me.jellysquid.mods.sodium.mixin.features.render.immediate.matrix_stack;

import com.mojang.blaze3d.vertex.PoseStack;
import org.joml.Matrix3f;
import org.joml.Matrix4f;
import org.spongepowered.asm.mixin.*;

import java.util.ArrayDeque;
import java.util.Deque;

@Mixin(PoseStack.class)
public abstract class MatrixStackMixin {
    @Shadow
    @Final
    private Deque<PoseStack.Entry> stack;

    @Unique
    private final Deque<PoseStack.Entry> cache = new ArrayDeque<>();


    /**
     * @author JellySquid
     * @reason Re-use entries when possible
     */
    @Overwrite
    public void push() {
        var prev = this.stack.getLast();

        PoseStack.Entry entry;

        if (!this.cache.isEmpty()) {
            entry = this.cache.removeLast();
            entry.getPositionMatrix()
                    .set(prev.getPositionMatrix());
            entry.getNormalMatrix()
                    .set(prev.getNormalMatrix());
        } else {
            entry = new PoseStack.Entry(new Matrix4f(prev.getPositionMatrix()), new Matrix3f(prev.getNormalMatrix()));
        }

        this.stack.addLast(entry);
    }

    /**
     * @author JellySquid
     * @reason Re-use entries when possible
     */
    @Overwrite
    public void pop() {
        this.cache.addLast(this.stack.removeLast());
    }
}
