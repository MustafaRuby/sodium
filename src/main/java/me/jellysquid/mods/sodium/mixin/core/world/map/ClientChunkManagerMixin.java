package me.jellysquid.mods.sodium.mixin.core.world.map;

import me.jellysquid.mods.sodium.client.render.chunk.map.ChunkStatus;
import me.jellysquid.mods.sodium.client.render.chunk.map.ChunkTrackerHolder;
import net.minecraft.client.multiplayer.ClientChunkCache;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.network.protocol.game.ClientboundLevelChunkPacketData;
import net.minecraft.world.level.ChunkPos;
import net.minecraft.world.level.chunk.LevelChunk;
import org.jetbrains.annotations.Nullable;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import java.util.function.Consumer;

@Mixin(ClientChunkCache.class)
public class ClientChunkManagerMixin {
    @Shadow
    @Final
    ClientLevel world;

    @Inject(
            method = "unload",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/client/world/ClientChunkCache$ClientChunkMap;compareAndSet(ILnet/minecraft/world/chunk/LevelChunk;Lnet/minecraft/world/chunk/LevelChunk;)Lnet/minecraft/world/chunk/LevelChunk;",
                    shift = At.Shift.AFTER
            )
    )
    private void onChunkUnloaded(int chunkX, int chunkZ, CallbackInfo ci) {
        ChunkTrackerHolder.get(this.world)
                .onChunkStatusRemoved(chunkX, chunkZ, ChunkStatus.FLAG_HAS_BLOCK_DATA);
    }

    @Inject(
            method = "loadChunkFromPacket",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/client/world/ClientLevel;resetChunkColor(Lnet/minecraft/util/math/ChunkPos;)V",
                    shift = At.Shift.AFTER
            )
    )
    private void onChunkLoaded(int chunkX, int chunkZ, FriendlyByteBuf buf, CompoundTag nbt, Consumer<ChunkData.BlockEntityVisitor> consumer, CallbackInfoReturnable<@Nullable LevelChunk> cir) {
        ChunkTrackerHolder.get(this.world)
                .onChunkStatusAdded(chunkX, chunkZ, ChunkStatus.FLAG_HAS_BLOCK_DATA);
    }
}
