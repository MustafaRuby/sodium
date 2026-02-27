# Yarn -> Mojang single-pass sed script
# Safe to re-run: already-remapped patterns simply won't match

# Phase 1: Import paths (ALL patterns - safe to re-run)
# CLIENT RENDER MODEL JSON
s|net\.minecraft\.client\.render\.model\.json\.JsonUnbakedModel|net.minecraft.client.renderer.block.model.BlockModel|g
s|net\.minecraft\.client\.render\.model\.BakedModel|net.minecraft.client.resources.model.BakedModel|g
s|net\.minecraft\.client\.render\.model\.BakedQuad|net.minecraft.client.renderer.block.model.BakedQuad|g
s|net\.minecraft\.client\.render\.model\.BakedQuadFactory|net.minecraft.client.renderer.block.model.FaceBakery|g
s|net\.minecraft\.client\.render\.model\.ModelLoader|net.minecraft.client.resources.model.ModelBakery|g
s|net\.minecraft\.client\.render\.model\.MultipartBakedModel|net.minecraft.client.resources.model.MultiPartBakedModel|g
s|net\.minecraft\.client\.render\.model\.WeightedBakedModel|net.minecraft.client.resources.model.WeightedBakedModel|g
s|net\.minecraft\.client\.render\.block\.entity\.BlockEntityRenderDispatcher|net.minecraft.client.renderer.blockentity.BlockEntityRenderDispatcher|g
s|net\.minecraft\.client\.render\.block\.entity\.BlockEntityRenderer|net.minecraft.client.renderer.blockentity.BlockEntityRenderer|g
s|net\.minecraft\.client\.render\.block\.BlockModelRenderer|net.minecraft.client.renderer.block.ModelBlockRenderer|g
s|net\.minecraft\.client\.render\.block\.BlockModels|net.minecraft.client.renderer.block.BlockModelShaper|g
s|net\.minecraft\.client\.render\.chunk\.ChunkBuilder|net.minecraft.client.renderer.chunk.ChunkRenderDispatcher|g
s|net\.minecraft\.client\.render\.chunk\.ChunkOcclusionDataBuilder|net.minecraft.client.renderer.chunk.VisGraph|g
s|net\.minecraft\.client\.render\.chunk\.ChunkOcclusionData|net.minecraft.client.renderer.chunk.VisibilitySet|g
s|net\.minecraft\.client\.render\.entity\.EntityRenderDispatcher|net.minecraft.client.renderer.entity.EntityRenderDispatcher|g
s|net\.minecraft\.client\.render\.entity\.EntityRenderer|net.minecraft.client.renderer.entity.EntityRenderer|g
s|net\.minecraft\.client\.render\.item\.ItemRenderer|net.minecraft.client.renderer.entity.ItemRenderer|g
s|net\.minecraft\.client\.render\.BackgroundRenderer|net.minecraft.client.renderer.FogRenderer|g
s|net\.minecraft\.client\.render\.BufferBuilderStorage|net.minecraft.client.renderer.RenderBuffers|g
s|net\.minecraft\.client\.render\.BufferBuilder|com.mojang.blaze3d.vertex.BufferBuilder|g
s|net\.minecraft\.client\.render\.BufferRenderer|com.mojang.blaze3d.vertex.BufferUploader|g
s|net\.minecraft\.client\.render\.Camera|net.minecraft.client.Camera|g
s|net\.minecraft\.client\.render\.CameraSubmersionType|net.minecraft.client.renderer.FogRenderer.FogMode|g
s|net\.minecraft\.client\.render\.Frustum|net.minecraft.client.renderer.culling.Frustum|g
s|net\.minecraft\.client\.render\.GameRenderer|net.minecraft.client.renderer.GameRenderer|g
s|net\.minecraft\.client\.render\.LightmapTextureManager|net.minecraft.client.renderer.LightTexture|g
s|net\.minecraft\.client\.render\.OverlayTexture|net.minecraft.client.renderer.texture.OverlayTexture|g
s|net\.minecraft\.client\.render\.RenderLayers|net.minecraft.client.renderer.ItemBlockRenderTypes|g
s|net\.minecraft\.client\.render\.RenderLayer|net.minecraft.client.renderer.RenderType|g
s|net\.minecraft\.client\.render\.VertexConsumerProvider|net.minecraft.client.renderer.MultiBufferSource|g
s|net\.minecraft\.client\.render\.VertexConsumer|com.mojang.blaze3d.vertex.VertexConsumer|g
s|net\.minecraft\.client\.render\.VertexFormats|com.mojang.blaze3d.vertex.DefaultVertexFormat|g
s|net\.minecraft\.client\.render\.VertexFormat|com.mojang.blaze3d.vertex.VertexFormat|g
s|net\.minecraft\.client\.render\.WorldRenderer|net.minecraft.client.renderer.LevelRenderer|g
s|net\.minecraft\.client\.render\.\*|net.minecraft.client.renderer.*|g
# CLIENT COLOR
s|net\.minecraft\.client\.color\.block\.BlockColorProvider|net.minecraft.client.color.block.BlockColor|g
s|net\.minecraft\.client\.color\.item\.ItemColorProvider|net.minecraft.client.color.item.ItemColor|g
s|net\.minecraft\.client\.color\.world\.BiomeColors|net.minecraft.client.renderer.BiomeColors|g
s|net\.minecraft\.client\.color\.world\.FoliageColors|net.minecraft.world.level.FoliageColor|g
s|net\.minecraft\.client\.color\.world\.GrassColors|net.minecraft.world.level.GrassColor|g
# CLIENT FONT
s|net\.minecraft\.client\.font\.GlyphRenderer|net.minecraft.client.gui.font.glyphs.BakedGlyph|g
s|net\.minecraft\.client\.font\.TextHandler|net.minecraft.client.StringSplitter|g
s|net\.minecraft\.client\.font\.TextRenderer|net.minecraft.client.gui.Font|g
# CLIENT GL
s|net\.minecraft\.client\.gl\.Framebuffer|com.mojang.blaze3d.pipeline.RenderTarget|g
s|net\.minecraft\.client\.gl\.GlUniform|com.mojang.blaze3d.shaders.Uniform|g
s|net\.minecraft\.client\.gl\.ShaderProgram|net.minecraft.client.renderer.ShaderInstance|g
s|net\.minecraft\.client\.gl\.VertexBuffer|com.mojang.blaze3d.vertex.VertexBuffer|g
s|net\.minecraft\.client\.gl\.WindowFramebuffer|com.mojang.blaze3d.pipeline.MainTarget|g
# CLIENT GUI
s|net\.minecraft\.client\.gui\.hud\.DebugHud|net.minecraft.client.gui.components.DebugScreenOverlay|g
s|net\.minecraft\.client\.gui\.hud\.InGameHud|net.minecraft.client.gui.Gui|g
s|net\.minecraft\.client\.gui\.navigation\.GuiNavigationPath|net.minecraft.client.gui.ComponentPath|g
s|net\.minecraft\.client\.gui\.navigation\.GuiNavigation|net.minecraft.client.gui.navigation.FocusNavigationEvent|g
s|net\.minecraft\.client\.gui\.screen\.narration\.NarrationMessageBuilder|net.minecraft.client.gui.narration.NarrationElementOutput|g
s|net\.minecraft\.client\.gui\.screen\.narration\.NarrationPart|net.minecraft.client.gui.narration.NarratedElementType|g
s|net\.minecraft\.client\.gui\.screen\.DownloadingTerrainScreen|net.minecraft.client.gui.screens.ReceivingLevelScreen|g
s|net\.minecraft\.client\.gui\.screen\.LevelLoadingScreen|net.minecraft.client.gui.screens.LevelLoadingScreen|g
s|net\.minecraft\.client\.gui\.screen\.option\.OptionsScreen|net.minecraft.client.gui.screens.OptionsScreen|g
s|net\.minecraft\.client\.gui\.screen\.option\.VideoOptionsScreen|net.minecraft.client.gui.screens.VideoSettingsScreen|g
s|net\.minecraft\.client\.gui\.screen\.Screen|net.minecraft.client.gui.screens.Screen|g
s|net\.minecraft\.client\.gui\.widget\.ButtonWidget|net.minecraft.client.gui.components.Button|g
s|net\.minecraft\.client\.gui\.DrawContext|net.minecraft.client.gui.GuiGraphics|g
s|net\.minecraft\.client\.gui\.Drawable|net.minecraft.client.gui.components.Renderable|g
s|net\.minecraft\.client\.gui\.Element|net.minecraft.client.gui.components.events.GuiEventListener|g
s|net\.minecraft\.client\.gui\.ScreenRect|net.minecraft.client.gui.navigation.ScreenRectangle|g
s|net\.minecraft\.client\.gui\.Selectable|net.minecraft.client.gui.narration.NarratableEntry|g
# CLIENT INPUT
s|net\.minecraft\.client\.input\.KeyCodes|com.mojang.blaze3d.platform.InputConstants|g
# CLIENT MODEL
s|net\.minecraft\.client\.model\.ModelPart|net.minecraft.client.model.geom.ModelPart|g
# CLIENT NETWORK
s|net\.minecraft\.client\.network\.ClientPlayNetworkHandler|net.minecraft.client.multiplayer.ClientPacketListener|g
s|net\.minecraft\.client\.network\.ClientPlayerEntity|net.minecraft.client.player.LocalPlayer|g
# CLIENT OPTION
s|net\.minecraft\.client\.option\.CloudRenderMode|net.minecraft.client.CloudStatus|g
s|net\.minecraft\.client\.option\.GameOptions|net.minecraft.client.Options|g
s|net\.minecraft\.client\.option\.GraphicsMode|net.minecraft.client.GraphicsStatus|g
s|net\.minecraft\.client\.option\.SimpleOption|net.minecraft.client.OptionInstance|g
s|net\.minecraft\.client\.option\.\*|net.minecraft.client.*|g
# CLIENT PARTICLE
s|net\.minecraft\.client\.particle\.BillboardParticle|net.minecraft.client.particle.SingleQuadParticle|g
s|net\.minecraft\.client\.particle\.SpriteBillboardParticle|net.minecraft.client.particle.TextureSheetParticle|g
# CLIENT SOUND
s|net\.minecraft\.client\.sound\.PositionedSoundInstance|net.minecraft.client.resources.sounds.SimpleSoundInstance|g
# CLIENT TEXTURE
s|net\.minecraft\.client\.texture\.NativeImageBackedTexture|net.minecraft.client.renderer.texture.DynamicTexture|g
s|net\.minecraft\.client\.texture\.NativeImage|com.mojang.blaze3d.platform.NativeImage|g
s|net\.minecraft\.client\.texture\.PlayerSkinTexture|net.minecraft.client.renderer.texture.HttpTexture|g
s|net\.minecraft\.client\.texture\.SpriteAtlasTexture|net.minecraft.client.renderer.texture.TextureAtlas|g
s|net\.minecraft\.client\.texture\.SpriteContents|net.minecraft.client.renderer.texture.SpriteContents|g
s|net\.minecraft\.client\.texture\.Sprite|net.minecraft.client.renderer.texture.TextureAtlasSprite|g
s|net\.minecraft\.client\.texture\.TextureManager|net.minecraft.client.renderer.texture.TextureManager|g
s|net\.minecraft\.client\.texture\.AbstractTexture|net.minecraft.client.renderer.texture.AbstractTexture|g
s|net\.minecraft\.client\.texture\.MipmapHelper|net.minecraft.client.renderer.texture.MipmapGenerator|g
# CLIENT UTIL
s|net\.minecraft\.client\.util\.InputUtil|com.mojang.blaze3d.platform.InputConstants|g
s|net\.minecraft\.client\.util\.Window|com.mojang.blaze3d.platform.Window|g
s|net\.minecraft\.client\.util\.math\.MatrixStack|com.mojang.blaze3d.vertex.PoseStack|g
s|net\.minecraft\.client\.util\.math\.Rect2i|net.minecraft.client.renderer.Rect2i|g
# CLIENT WORLD
s|net\.minecraft\.client\.world\.ClientChunkManager|net.minecraft.client.multiplayer.ClientChunkCache|g
s|net\.minecraft\.client\.world\.ClientWorld|net.minecraft.client.multiplayer.ClientLevel|g
# CLIENT CORE
s|net\.minecraft\.client\.MinecraftClient|net.minecraft.client.Minecraft|g
s|net\.minecraft\.client\.RunArgs|net.minecraft.client.main.GameConfig|g
# BLOCK (specific first)
s|net\.minecraft\.block\.entity\.BlockEntity|net.minecraft.world.level.block.entity.BlockEntity|g
s|net\.minecraft\.block\.BlockRenderType|net.minecraft.world.level.block.RenderShape|g
s|net\.minecraft\.block\.BlockState|net.minecraft.world.level.block.state.BlockState|g
s|net\.minecraft\.block\.Blocks|net.minecraft.world.level.block.Blocks|g
s|net\.minecraft\.block\.SideShapeType|net.minecraft.world.level.block.SupportType|g
s|net\.minecraft\.block\.Block;|net.minecraft.world.level.block.Block;|g
s|net\.minecraft\.block\.Block\.|net.minecraft.world.level.block.Block.|g
s|net\.minecraft\.block\.\*|net.minecraft.world.level.block.*|g
# ENTITY
s|net\.minecraft\.entity\.effect\.StatusEffectInstance|net.minecraft.world.effect.MobEffectInstance|g
s|net\.minecraft\.entity\.effect\.StatusEffects|net.minecraft.world.effect.MobEffects|g
s|net\.minecraft\.entity\.Entity|net.minecraft.world.entity.Entity|g
# FLUID
s|net\.minecraft\.fluid\.FluidState|net.minecraft.world.level.material.FluidState|g
s|net\.minecraft\.fluid\.Fluids|net.minecraft.world.level.material.Fluids|g
s|net\.minecraft\.fluid\.Fluid;|net.minecraft.world.level.material.Fluid;|g
s|net\.minecraft\.fluid\.Fluid\.|net.minecraft.world.level.material.Fluid.|g
# ITEM
s|net\.minecraft\.item\.ItemConvertible|net.minecraft.world.level.ItemLike|g
s|net\.minecraft\.item\.ItemStack|net.minecraft.world.item.ItemStack|g
# NBT
s|net\.minecraft\.nbt\.NbtCompound|net.minecraft.nbt.CompoundTag|g
# NETWORK
s|net\.minecraft\.network\.packet\.s2c\.play\.ChunkData|net.minecraft.network.protocol.game.ClientboundLevelChunkPacketData|g
s|net\.minecraft\.network\.packet\.s2c\.play\.LightData|net.minecraft.network.protocol.game.ClientboundLightUpdatePacketData|g
s|net\.minecraft\.network\.packet\.s2c\.play\.UnloadChunkS2CPacket|net.minecraft.network.protocol.game.ClientboundForgetLevelChunkPacket|g
s|net\.minecraft\.network\.PacketByteBuf|net.minecraft.network.FriendlyByteBuf|g
# REGISTRY
s|net\.minecraft\.registry\.entry\.RegistryEntry|net.minecraft.core.Holder|g
s|net\.minecraft\.registry\.tag\.FluidTags|net.minecraft.tags.FluidTags|g
s|net\.minecraft\.registry\.RegistryKeys|net.minecraft.core.registries.Registries|g
s|net\.minecraft\.registry\.RegistryKey|net.minecraft.resources.ResourceKey|g
s|net\.minecraft\.registry\.Registries|net.minecraft.core.registries.BuiltInRegistries|g
# RESOURCE
s|net\.minecraft\.resource\.metadata\.ResourceMetadataSerializer|net.minecraft.server.packs.metadata.MetadataSectionSerializer|g
s|net\.minecraft\.resource\.ReloadableResourceManagerImpl|net.minecraft.server.packs.resources.ReloadableResourceManager|g
s|net\.minecraft\.resource\.ResourceFactory|net.minecraft.server.packs.resources.ResourceProvider|g
s|net\.minecraft\.resource\.ResourceManager|net.minecraft.server.packs.resources.ResourceManager|g
s|net\.minecraft\.resource\.ResourceReload|net.minecraft.server.packs.resources.ReloadInstance|g
s|net\.minecraft\.resource\.Resource;|net.minecraft.server.packs.resources.Resource;|g
s|net\.minecraft\.resource\.\*|net.minecraft.server.packs.resources.*|g
# SOUND
s|net\.minecraft\.sound\.SoundEvents|net.minecraft.sounds.SoundEvents|g
# TEXT
s|net\.minecraft\.text\.MutableText|net.minecraft.network.chat.MutableComponent|g
s|net\.minecraft\.text\.OrderedText|net.minecraft.util.FormattedCharSequence|g
s|net\.minecraft\.text\.StringVisitable|net.minecraft.network.chat.FormattedText|g
s|net\.minecraft\.text\.Style|net.minecraft.network.chat.Style|g
s|net\.minecraft\.text\.Text|net.minecraft.network.chat.Component|g
# UTIL (specific first)
s|net\.minecraft\.util\.collection\.EmptyPaletteStorage|net.minecraft.util.ZeroBitStorage|g
s|net\.minecraft\.util\.collection\.PackedIntegerArray|net.minecraft.util.SimpleBitStorage|g
s|net\.minecraft\.util\.crash\.CrashException|net.minecraft.ReportedException|g
s|net\.minecraft\.util\.crash\.CrashReportSection|net.minecraft.CrashReportCategory|g
s|net\.minecraft\.util\.crash\.CrashReport|net.minecraft.CrashReport|g
s|net\.minecraft\.util\.function\.BooleanBiFunction|net.minecraft.world.phys.shapes.BooleanOp|g
s|net\.minecraft\.util\.hit\.BlockHitResult|net.minecraft.world.phys.BlockHitResult|g
s|net\.minecraft\.util\.math\.random\.LocalRandom|net.minecraft.world.level.levelgen.SingleThreadedRandomSource|g
s|net\.minecraft\.util\.math\.random\.Random|net.minecraft.util.RandomSource|g
s|net\.minecraft\.util\.math\.BlockBox|net.minecraft.world.level.levelgen.structure.BoundingBox|g
s|net\.minecraft\.util\.math\.BlockPos|net.minecraft.core.BlockPos|g
s|net\.minecraft\.util\.math\.Box|net.minecraft.world.phys.AABB|g
s|net\.minecraft\.util\.math\.ChunkPos|net.minecraft.world.level.ChunkPos|g
s|net\.minecraft\.util\.math\.ChunkSectionPos|net.minecraft.core.SectionPos|g
s|net\.minecraft\.util\.math\.ColorHelper|net.minecraft.util.FastColor|g
s|net\.minecraft\.util\.math\.Direction|net.minecraft.core.Direction|g
s|net\.minecraft\.util\.math\.MathHelper|net.minecraft.util.Mth|g
s|net\.minecraft\.util\.math\.Vec3d|net.minecraft.world.phys.Vec3|g
s|net\.minecraft\.util\.math\.Vec3i|net.minecraft.core.Vec3i|g
s|net\.minecraft\.util\.math\.\*|net.minecraft.core.*|g
s|net\.minecraft\.util\.profiler\.Profiler|net.minecraft.util.profiling.ProfilerFiller|g
s|net\.minecraft\.util\.shape\.VoxelShapes|net.minecraft.world.phys.shapes.Shapes|g
s|net\.minecraft\.util\.shape\.VoxelShape|net.minecraft.world.phys.shapes.VoxelShape|g
s|net\.minecraft\.util\.Formatting|net.minecraft.ChatFormatting|g
s|net\.minecraft\.util\.Identifier|net.minecraft.resources.ResourceLocation|g
s|net\.minecraft\.util\.Language|net.minecraft.locale.Language|g
s|net\.minecraft\.util\.Util|net.minecraft.Util|g
# WORLD
s|net\.minecraft\.world\.biome\.source\.BiomeCoords|net.minecraft.world.level.biome.BiomeResolver|g
s|net\.minecraft\.world\.biome\.BiomeEffects|net.minecraft.world.level.biome.BiomeSpecialEffects|g
s|net\.minecraft\.world\.biome\.BiomeKeys|net.minecraft.world.level.biome.Biomes|g
s|net\.minecraft\.world\.biome\.Biome;|net.minecraft.world.level.biome.Biome;|g
s|net\.minecraft\.world\.biome\.Biome\.|net.minecraft.world.level.biome.Biome.|g
s|net\.minecraft\.world\.biome\.ColorResolver|net.minecraft.world.level.ColorResolver|g
s|net\.minecraft\.world\.chunk\.light\.LightingProvider|net.minecraft.world.level.lighting.LevelLightEngine|g
s|net\.minecraft\.world\.chunk\.ChunkNibbleArray|net.minecraft.world.level.chunk.DataLayer|g
s|net\.minecraft\.world\.chunk\.ChunkSection|net.minecraft.world.level.chunk.LevelChunkSection|g
s|net\.minecraft\.world\.chunk\.ChunkStatus|net.minecraft.world.level.chunk.ChunkStatus|g
s|net\.minecraft\.world\.chunk\.PalettedContainer|net.minecraft.world.level.chunk.PalettedContainer|g
s|net\.minecraft\.world\.chunk\.Palette;|net.minecraft.world.level.chunk.Palette;|g
s|net\.minecraft\.world\.chunk\.Palette\.|net.minecraft.world.level.chunk.Palette.|g
s|net\.minecraft\.world\.chunk\.ReadableContainer|net.minecraft.world.level.chunk.PalettedContainerRO|g
s|net\.minecraft\.world\.chunk\.WorldChunk|net.minecraft.world.level.chunk.LevelChunk|g
s|net\.minecraft\.world\.chunk\.Chunk;|net.minecraft.world.level.chunk.ChunkAccess;|g
s|net\.minecraft\.world\.chunk\.\*|net.minecraft.world.level.chunk.*|g
s|net\.minecraft\.world\.dimension\.DimensionType|net.minecraft.world.level.dimension.DimensionType|g
s|net\.minecraft\.world\.gen\.chunk\.DebugChunkGenerator|net.minecraft.world.level.levelgen.DebugLevelSource|g
s|net\.minecraft\.world\.BlockRenderView|net.minecraft.world.level.BlockAndTintGetter|g
s|net\.minecraft\.world\.BlockView|net.minecraft.world.level.BlockGetter|g
s|net\.minecraft\.world\.LightType|net.minecraft.world.level.LightLayer|g
s|net\.minecraft\.world\.WorldView|net.minecraft.world.level.LevelReader|g
s|net\.minecraft\.world\.World;|net.minecraft.world.level.Level;|g
s|net\.minecraft\.world\.World\.|net.minecraft.world.level.Level.|g

# Phase 2: Class name usage in code
s|MinecraftClient|Minecraft|g
s|SideShapeType|SupportType|g
s|BlockColorProvider|BlockColor|g
s|ItemColorProvider|ItemColor|g
s|FoliageColors|FoliageColor|g
s|GrassColors|GrassColor|g
s|TextRenderer|Font|g
s|ShaderProgram|ShaderInstance|g
s|DrawContext|GuiGraphics|g
s|InGameHud|Gui|g
s|ButtonWidget|Button|g
s|BackgroundRenderer|FogRenderer|g
s|BufferBuilderStorage|RenderBuffers|g
s|LightmapTextureManager|LightTexture|g
s|RenderLayers|ItemBlockRenderTypes|g
s|RenderLayer|RenderType|g
s|VertexConsumerProvider|MultiBufferSource|g
s|VertexFormats|DefaultVertexFormat|g
s|WorldRenderer|LevelRenderer|g
s|BlockModelRenderer|ModelBlockRenderer|g
s|SpriteAtlasTexture|TextureAtlas|g
s|NativeImageBackedTexture|DynamicTexture|g
s|MatrixStack|PoseStack|g
s|ClientChunkManager|ClientChunkCache|g
s|ClientWorld|ClientLevel|g
s|ClientPlayNetworkHandler|ClientPacketListener|g
s|ClientPlayerEntity|LocalPlayer|g
s|CloudRenderMode|CloudStatus|g
s|GameOptions|Options|g
s|GraphicsMode|GraphicsStatus|g
s|SimpleOption|OptionInstance|g
s|SpriteBillboardParticle|TextureSheetParticle|g
s|BillboardParticle|SingleQuadParticle|g
s|StatusEffectInstance|MobEffectInstance|g
s|StatusEffects|MobEffects|g
s|ItemConvertible|ItemLike|g
s|NbtCompound|CompoundTag|g
s|PacketByteBuf|FriendlyByteBuf|g
s|RegistryEntry|Holder|g
s|MutableText|MutableComponent|g
s|OrderedText|FormattedCharSequence|g
s|Identifier|ResourceLocation|g
s|Formatting|ChatFormatting|g
s|MathHelper|Mth|g
s|ChunkSectionPos|SectionPos|g
s|BlockBox|BoundingBox|g
s|Vec3d|Vec3|g
s|VoxelShapes|Shapes|g
s|BlockRenderView|BlockAndTintGetter|g
s|BlockView|BlockGetter|g
s|LightType|LightLayer|g
s|WorldView|LevelReader|g
s|ChunkNibbleArray|DataLayer|g
s|WorldChunk|LevelChunk|g
s|LightingProvider|LevelLightEngine|g
s|BlockRenderType|RenderShape|g

# Phase 3: Method renames
s|\.getDefaultState()|.defaultBlockState()|g
s|\.isOpaque()|.canOcclude()|g
s|\.getCullingShape(|.getOcclusionShape(|g
s|\.isSideSolid(|.isFaceSturdy(|g
s|\.getOffsetX()|.getStepX()|g
s|\.getOffsetY()|.getStepY()|g
s|\.getOffsetZ()|.getStepZ()|g
s|\.matchesType(|.isSame(|g
s|\.getFrameU(|.getU(|g
s|\.getFrameV(|.getV(|g
s|\.getMinU()|.getU0()|g
s|\.getMinV()|.getV0()|g
s|\.getMaxU()|.getU1()|g
s|\.getMaxV()|.getV1()|g
s|\.getVelocity(|.getFlow(|g
s|\.isIn(|.is(|g
s|\.getLightingProvider(|.getLightEngine(|g
s|\.getSectionArray()|.getSections()|g
s|\.sectionCoordToIndex(|.getSectionIndexFromSectionY(|g
s|\.getBrightness(|.getShade(|g
s|\.getSession()|.getUser()|g
s|\.getUuidOrNull()|.getProfileId()|g
s|\.getBakedModelManager()|.getModelManager()|g
s|\.getContents()|.contents()|g
s|Text\.translatable(|Component.translatable(|g
s|Text\.literal(|Component.literal(|g
s|\.isAmbientOcclusionEnabled()|.useAmbientOcclusion()|g
s|\.getMinX()|.minX()|g
s|\.getMinY()|.minY()|g
s|\.getMinZ()|.minZ()|g
s|\.getMaxX()|.maxX()|g
s|\.getMaxY()|.maxY()|g
s|\.getMaxZ()|.maxZ()|g
