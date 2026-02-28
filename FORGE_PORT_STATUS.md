# Sodium Forge Port — Status & Notes

## Why am I doing this?

Better MC is a Forge-only modpack, and it runs like garbage on low-end hardware. Sodium is hands down the best rendering optimization mod for Minecraft, but it's Fabric-only. My friends and I want to play Better MC together without the slideshow experience, so I'm porting Sodium 0.5.13 to Forge 1.20.1 myself.

The core problem: Fabric mods use "Yarn" mappings for Minecraft's obfuscated code, while Forge uses "Mojang official" mappings. Same game, completely different names for everything. So this port is mostly a massive renaming operation across 415 Java files, plus swapping out Fabric's mod loader API for Forge's.

---

**Branch:** `1.20.1/stable-0.5`
**Source:** Sodium 0.5.13 (Fabric/Yarn)
**Target:** Forge 1.20.1 (Mojang mappings)
**Last updated:** 2026-02-28
**Build status:** 0 errors, 100 warnings — compiles successfully

---

## What's done

### Build system (Session 1)

Ripped out Fabric Loom, replaced with ForgeGradle + MixinGradle.

| File | What changed |
|------|-------------|
| `build.gradle.kts` | ForgeGradle + MixinGradle. `mappings("official", "1.20.1")`, Forge 1.20.1-47.3.0. |
| `settings.gradle.kts` | Plugin repos for ForgeGradle + MixinGradle (maven.minecraftforge.net, SpongePowered). |
| `gradle.properties` | ForgeGradle properties. |

### Forge metadata (Session 1)

| File | What happened |
|------|--------------|
| `src/main/resources/META-INF/mods.toml` | Created — replaces `fabric.mod.json`. |
| `src/main/resources/META-INF/accesstransformer.cfg` | Created — replaces `sodium.accesswidener`. |
| `src/main/resources/pack.mcmeta` | Created. |
| `src/main/resources/fabric.mod.json` | Deleted. |
| `src/main/resources/sodium.accesswidener` | Deleted. |

### Fabric API -> Forge API (Session 1)

Converted 6 files from Fabric's mod loader to Forge's:

| File | What changed |
|------|-------------|
| `SodiumClientMod.java` | `ModInitializer` -> `@Mod("sodium")` + `FMLJavaModLoadingContext`. `FabricLoader` -> `ModList`. `Text.translatable()` -> `Component.translatable()`. |
| `MixinConfig.java` | `FabricLoader.getInstance()` -> `ModList.get()`. `ModContainer` -> `IModInfo`. |
| `SodiumPreLaunch.java` | Fabric `PreLaunchEntrypoint` -> static initializer called from mod constructor. |
| `FingerprintMeasure.java` | `FabricLoader` path resolution -> `ModList`/`FMLPaths`. |
| `HashedFingerprint.java` | Same loader API swap. |
| `FluidRenderer.java` | `FluidRenderHandler` (Fabric) -> `IClientFluidTypeExtensions` (Forge). Full rewrite of fluid color/sprite lookup. |
| `DefaultColorProviders.java` | New `ForgeFluidAdapter` using `IClientFluidTypeExtensions.getTintColor()`. |

### Yarn -> Mojang remapping (Session 2)

Built a `remap.sed` script (~200 patterns) and ran it across all 415 source files in one pass:

```
find src -name "*.java" -type f -print0 | xargs -0 sed -i -f remap.sed
```

Three phases of replacements:

**Phase 1 — Import paths (~120 patterns)**

| Yarn | Mojang |
|------|--------|
| `net.minecraft.client.render.*` | `net.minecraft.client.renderer.*` |
| `net.minecraft.client.render.model.*` | `net.minecraft.client.resources.model.*` |
| `net.minecraft.client.render.chunk.*` | `net.minecraft.client.renderer.chunk.*` |
| `net.minecraft.client.texture.*` | `net.minecraft.client.renderer.texture.*` |
| `net.minecraft.client.gui.screen.*` | `net.minecraft.client.gui.screens.*` |
| `net.minecraft.client.gui.widget.*` | `net.minecraft.client.gui.components.*` |
| `net.minecraft.client.option.*` | `net.minecraft.client.*` (Options class) |
| `net.minecraft.util.math.*` | `net.minecraft.core.*` / `net.minecraft.world.phys.*` |
| `net.minecraft.util.Identifier` | `net.minecraft.resources.ResourceLocation` |
| `net.minecraft.block.*` | `net.minecraft.world.level.block.*` |
| `net.minecraft.fluid.*` | `net.minecraft.world.level.material.*` |
| `net.minecraft.world.chunk.*` | `net.minecraft.world.level.chunk.*` |
| `net.minecraft.world.biome.*` | `net.minecraft.world.level.biome.*` |
| `net.minecraft.text.*` | `net.minecraft.network.chat.*` |
| `net.minecraft.util.math.random.*` | `net.minecraft.util.*` |
| `net.minecraft.util.registry.*` | `net.minecraft.core.registries.*` |

**Phase 2 — Class names in code body (~50 patterns)**

| Yarn | Mojang |
|------|--------|
| `MinecraftClient` | `Minecraft` |
| `GameOptions` | `Options` |
| `ClientWorld` | `ClientLevel` |
| `ServerWorld` | `ServerLevel` |
| `WorldRenderer` | `LevelRenderer` |
| `WorldChunk` | `LevelChunk` |
| `ChunkSection` | `LevelChunkSection` |
| `ChunkNibbleArray` | `DataLayer` |
| `LightType` | `LightLayer` |
| `BlockRenderView` | `BlockAndTintGetter` |
| `RegistryEntry` | `Holder` |
| `Formatting` | `ChatFormatting` |
| `ButtonWidget` | `Button` |
| `TextRenderer` | `Font` |
| `Tessellator` | `Tesselator` |
| `ChunkBuilder` | `ChunkRenderDispatcher` |
| `DrawableHelper` | `GuiComponent` |
| ...plus ~30 more | |

**Phase 3 — Method names (~30 patterns)**

| Yarn | Mojang |
|------|--------|
| `.textRenderer` | `.font` |
| `.drawTextWithShadow()` | `.drawString()` |
| `.getWidth()` on Text | `.width()` |
| `.isSame()` | `.is()` (Fluid) |
| `.getMinU/V()` / `.getMaxU/V()` | `.getU0/V0()` / `.getU1/V1()` |
| and others... | |

### Cleanup after the sed nuke (Session 2)

The Phase 2 bare string replacements were too aggressive — they renamed Sodium's own classes, not just Minecraft references. `s|GameOptions|Options|g` turned `SodiumGameOptions` into `SodiumOptions`, `s|Formatting|ChatFormatting|g` cascaded into `ChatChatChatChatFormatting`, etc. Had to go through ~35 files and revert those:

| File | Got renamed to | Reverted back to |
|------|---------------|-----------------|
| `SodiumGameOptions.java` | `SodiumOptions` | `SodiumGameOptions` |
| `SodiumOptionsGUI.java` | `SodiumGameOptionsGUI` | `SodiumOptionsGUI` |
| `SodiumOptionsStorage.java` | `SodiumGameOptionsStorage` | `SodiumOptionsStorage` |
| `SodiumWorldRenderer.java` | `SodiumLevelRenderer` | `SodiumWorldRenderer` |
| `ChunkBuilder.java` (Sodium's own) | `ChunkRenderDispatcher` | `ChunkBuilder` |
| `FlatButtonWidget.java` | `FlatButton` | `FlatButtonWidget` |
| 29 mixin files | Various wrong names | Original names matching filenames |

Also did a bunch of targeted fixes after the bulk remap:
- `Text` -> `Component` in GUI files
- `Element` -> `GuiEventListener`
- `StringVisitable` -> `FormattedText`
- `Sprite` -> `TextureAtlasSprite`
- `ReadableContainer` -> `PalettedContainerRO`
- `BlockPos.Mutable` -> `BlockPos.MutableBlockPos`
- `SpriteAtlasTexture` -> `TextureAtlas`
- Added missing imports (`BoundingBox`, `PathPackResources`, etc.)

Fixed mixin string-based targets for inner classes:

| File | Old (Yarn) | New (Mojang) |
|------|-----------|-------------|
| `OutlineVertexConsumerMixin.java` | `...OutlineMultiBufferSource$OutlineVertexConsumer` | `...OutlineBufferSource$EntityOutlineGenerator` |
| `VertexConsumersMixin.java` | `...VertexMultiConsumer$Dual` | `...VertexMultiConsumer$Double` |
| `VertexConsumersMixin.java` | `...VertexMultiConsumer$Union` | `...VertexMultiConsumer$Multiple` |

### Method-level remapping (Sessions 3–5)

The sed script handled imports and class names but didn't touch most method calls, field references, @Shadow names, @Overwrite methods, @Inject/@Redirect target descriptors, or inner class names. That left ~400+ compile errors across ~120 files after the sed pass. Fixed them in waves — each wave of fixes unblocked the next set of files, which revealed their own errors.

**Wave 1 — World, biome, and light data (~70 errors across 9 files)**

| File | Errors | Key renames |
|------|--------|------------|
| `WorldSlice.java` | ~28 | `SectionPos.minX()` -> `minBlockX()`, `volume.contains()` -> `isInside()`, `getShade()`, `getBrightness()`, `getRawBrightness()`, `getBlockTint()`, `getMinBuildHeight()`, `getSectionIndex()` |
| `BiomeSlice.java` | ~22 | `Climate.mixSeed()` -> `LinearCongruentialGenerator.next()`, `BiomeCoords` -> `QuartPos` (moved to `net.minecraft.core.QuartPos`), `registryAccess().registryOrThrow(Registries.BIOME).getHolderOrThrow(Biomes.PLAINS)` |
| `BiomeColorCache.java` | ~9 | `SectionPos.minBlockX()/maxBlockX()`, `BiomeColors.GRASS_COLOR` -> `GRASS_COLOR_RESOLVER` (same for FOLIAGE and WATER) |
| `BiomeColorSource.java` | 3 | Same `BiomeColors` constant renames |
| `ClonedChunkSection.java` | ~20 | `Block.STATE_IDS` -> `BLOCK_STATE_REGISTRY`, `PalettedContainer.Strategy.BLOCK_STATE` -> `SECTION_STATES`, `hasOnlyAir()`, `isDebug()`, `getStates()`, `getBiomes()`, `DebugLevelSource.getBlockStateFor()`, `SectionPos.sectionToBlockCoord()`, `dimensionType().hasSkyLight()`, `getLightEngine().getLayerListener(type).getDataLayerData(pos)`, `getAndSetUnchecked()`, `getModelData()` |
| `ClonedChunkSectionCache.java` | 2 | `isOutsideBuildHeight()`, `getSectionIndex()`, `SectionPos.of()` |
| `LightDataAccess.java` | ~10 | `emissiveRendering()`, `isSuffocating()`, `getLightBlock()`, `isSolidRender()`, `isCollisionShapeFullBlock()`, `getLightEmission()`, `getShadeBrightness()`, `LightTexture.FULL_BRIGHT` |
| `ArrayLightDataCache.java` | 3 | `origin.minBlockX/Y/Z()` |
| `FlatLightPipeline.java` | 1 | `LightTexture.FULL_BRIGHT` |

**Wave 2 — Rendering core (~100 errors across 23 files)**

Fixing the world/biome/light files unblocked the entire rendering pipeline. Every file that depended on `WorldSlice`, `ClonedChunkSection`, or the light data now revealed its own Yarn method names.

| File | Errors | Key renames |
|------|--------|------------|
| `FluidRenderer.java` | 19 | `getType()`, `Shapes.box()`, `Shapes.blockOccudes()` (sic — that's the Mojang typo, not mine), `setWithOffset()`, `contents().height()`, `shouldRenderBackwardUpFace()`, `shouldDisplayFluidOverlay()`, `TextureAtlas.LOCATION_BLOCKS`, `above()`, `getOwnHeight()` |
| `ChunkBuilderMeshingTask.java` | 12 | `getRenderShape()`, `getBlockModel()`, `getSeed()`, `getRenderer()`, `shouldRenderOffScreen()`, `isSolidRender()`, `CrashReport.forThrowable()` |
| `RenderSectionManager.java` | 11 | `smartCull`, `ChunkAccess`, `hasOnlyAir()`, `Mth.equal()`, `getMinSection()/getMaxSection()` |
| `BlockRenderer.java` | 7 | `SingleThreadedRandomSource`, `hasOffsetFunction()`, `getOffset()`, `offset.x()/y()/z()`, `getLightEmission()` |
| `BlockOcclusionCache.java` | 6 | `skipRendering()`, `getFaceOcclusionShape()`, `Shapes.block()`, `Shapes.joinIsNotEmpty()` |
| `ChunkTracker.java` | 6 | `ChunkPos.asLong()`, `ChunkPos.getX()/getZ()` |
| `DefaultMaterials.java` | 5 | `getChunkRenderType()`, `getRenderLayer()`, `RenderType.solid()/cutout()/cutoutMipped()/tripwire()/translucent()` |
| `Viewport.java` | 4 | `SectionPos.of()`, `SectionPos.blockToSectionCoord()`, `BlockPos.containing()` |
| `OcclusionCuller.java` | 4 | `getMinSection()/getMaxSection()` |
| `AoFaceData.java` | 4 | `LightTexture.FULL_BRIGHT` |
| `SmoothLightPipeline.java` | 3 | `Mth.equal()` |
| `DefaultTerrainRenderPasses.java` | 3 | `RenderType.solid()/cutoutMipped()/translucent()` |
| `TerrainRenderPass.java` | 2 | `setupRenderState()/clearRenderState()` |
| `ModelQuadUtil.java` | 2 | `face.step()`, `Mth.equal()` |
| `ChunkShaderInterface.java` | 2 | `TextureAtlas.LOCATION_BLOCKS`, `getWidth()` |
| `BuiltSectionInfo.java` | 1 | `setAll(true)` |
| `BlockRenderCache.java` | 1 | `getBlockModelShaper()` |
| `RenderSection.java` | 1 | `SectionPos.of()` |
| `VisibilityEncoding.java` | 1 | `Direction.from3DDataValue()` -> `get3DDataValue()` |
| `ChunkShaderFogComponent.java` | 1 | `getIndex()` |
| `AoNeighborInfo.java` | 1 | `get3DDataValue()` |
| `CommonVertexAttribute.java` | 1 | `DefaultVertexFormat.ELEMENT_POSITION/COLOR/UV0/UV1/UV2/NORMAL`, `getByteSize()` |
| `EntityRenderer.java` | 1 | `translateAndRotate()` |

**Wave 3 — CloudRenderer and SodiumWorldRenderer (~90 errors across 2 files)**

These two files are the biggest in the mod and had the most remaining Yarn names — nearly every rendering API call was wrong.

| File | Errors | Key renames |
|------|--------|------------|
| `CloudRenderer.java` | ~60 | `FogRenderer.FogMode`, `effects().getCloudHeight()`, `getCloudColor()`, `getEffectiveRenderDistance()`, `getCloudsType()`, `fogData.end/start`, `useShaderTransparency()`, `getCloudsTarget().bindWrite()`, `drawWithShader()`, `GlStateManager.SourceFactor/DestFactor`, `getMainRenderTarget().bindWrite()`, `getMainCamera()`, `FogType` (was `CameraSubmersionType`), `getFluidInCamera()`, `hasEffect()`, `getWaterVision()`, `fogData.shape`, `getPosition()`, `effects().isFoggyAt()`, `getBossOverlay().shouldCreateWorldFog()`, `MobEffectFogFunction/getPriorityFogFunction()`, `getEffect()/getMobEffect()`, `setupFog()`, `resource.open()`, `getPixelRGBA()`. Also fixed an access transformer entry in `accesstransformer.cfg`. |
| `SodiumWorldRenderer.java` | ~30 | `levelRenderer`, `getEffectiveRenderDistance()`, `getPosition()`, `getXRot()/getYRot()`, `popPush()`, `setViewScale()`, `entityDistanceScaling().get()`, `RenderType.solid()/translucent()`, `bufferSource()`, `getBlockPos()`, `getProgress()`, `crumblingBufferSource()`, `DESTROY_TYPES`, `affectsCrumbling()`, `create()`, `shouldEntityAppearGlowing()`, `shouldShowName()`, `getBoundingBoxForCulling()`, `getMinBuildHeight()/getMaxBuildHeight()`, `SectionPos.blockToSectionCoord()` |

**Wave 4 — Particles, buffers, vertex formats, colors, and remaining mixins (~100 errors across ~30 files)**

| File | Errors | Key renames |
|------|--------|------------|
| `BillboardParticleMixin.java` | 18 | `prevPosX/Y/Z` -> `xo/yo/zo`, `red/green/blue` -> `rCol/gCol/bCol`, `angle` -> `roll`, `prevAngle` -> `oRoll`, `camera.rotation()`, `getQuadSize()`, `getLightColor()`, `Vec3.x()/y()/z()`, `@Inject method = "render"` |
| `SodiumBufferBuilder.java` | 11 | `fixedColor()` -> `defaultColor()`, `unfixColor()` -> `unsetDefaultColor()`, `texture()` -> `uv()`, `overlay()` -> `overlayCoords()`, `light()` -> `uv2()`, `next()` -> `endVertex()` |
| `BufferBuilderMixin.java` (intrinsics) | 8 | `canSkipElementChecks` -> `fastFormat`, `quad()` -> `putBulkData()`, `colorFixed` -> `defaultColorSet`, `getVertexData()` -> `getVertices()` |
| `FastCubicSampler.java` | 11 | `Vec3.unpackRgb()` -> `fromRGB24()`, `color.multiply()` -> `scale()`, `pos.getX()` -> `x()` |
| `EntityRenderDispatcherMixin.java` | 7 | `renderShadowPart` -> `renderBlockShadow`, `pos.down()` -> `below()`, `getRenderType()` -> `getRenderShape()`, `isFullCube()` -> `isCollisionShapeFullBlock()`, `getLightLevel()` -> `getMaxLocalRawBrightness()`, `getOutlineShape()` -> `getShape()`, `LightTexture.getBrightness()`, `OverlayTexture.NO_OVERLAY` |
| `BiomeColorMaps.java` | 4 | `GrassColor.colorMap` -> `pixels`, `FoliageColor.colorMap` -> `pixels` |
| `OutlineVertexConsumerMixin.java` | 4 | `fixedRed/Green/Blue/Alpha` -> `defaultR/G/B/A` |
| `PalettedContainerMixin.java` | 4 | `paletteProvider` -> `strategy`, `getContainerSize()` -> `size()`, `computeIndex()` -> `getIndex()`, `palette.get()` -> `valueFor()` |
| `LevelLoadingScreenMixin.java` | 3 | `getCenterSize()` -> `getFullDiameter()`, `getSize()` -> `getDiameter()`, `getChunkStatus()` -> `getStatus()` |
| `BackgroundRendererMixin.java` | 3 | `getSkyAngle()` -> `getTimeOfDay()`, `getBiomeAccess().getBiomeForNoiseGen()` -> `getBiomeManager().getNoiseBiomeAtQuart()`, `getDimensionEffects().adjustFogColor()` -> `effects().getBrightnessDependentFogColor()` |
| `GameRendererMixin.java` (console) | 2 | `client` -> `minecraft`, `buffers.getEntityVertexMultiConsumer()` -> `renderBuffers.bufferSource()`, `draw()` -> `flush()` |
| `BlockModelRendererMixin.java` | 2 | `new LocalRandom(42L)` -> `new SingleThreadedRandomSource(42L)`, `getVertexData()` -> `getVertices()` |
| `ItemRendererMixin.java` | 2 | Same `LocalRandom` rename, `colors` -> `itemColors`, `renderBakedItemModel` -> `renderModelLists`, `getVertexData()` -> `getVertices()` |
| `VertexFormatDescriptionImpl.java` | 2 | `getVertexSizeByte()` -> `getVertexSize()`, `PADDING_ELEMENT` -> `ELEMENT_PADDING` |
| `NativeImageHelper.java` | 2 | `getFormat()` -> `format()` |
| `SpriteContentsInterpolationMixin.java` | 2 | `this.parent.getHeight()` -> `height()`, `src.width()` -> `getWidth()` |
| `BufferBuilderMixin.java` (sorting) | 2 | `getVertexSizeByte()` -> `getVertexSize()`, `indexType.size` -> `bytes` |
| `BufferBuilderMixin.java` (consumer) | 1 | `colorFixed` -> `defaultColorSet` |
| `OverlayVertexConsumerMixin.java` | 1 | `getRotationQuaternion()` -> `getRotation()` |
| `EmptyPaletteStorageMixin.java` | 1 | `palette.get(0)` -> `valueFor(0)` |
| `PackedIntegerArrayMixin.java` | 1 | Same `palette.get()` -> `valueFor()` |
| `DownloadingTerrainScreenMixin.java` | 1 | `BlockPos.ofFloored()` -> `containing()` |
| `BlockColorsMixin.java` | 1 | `Registries.BLOCK.getId()` -> `BuiltInRegistries.BLOCK.getKey()` |
| `WorldRendererMixin.java` (weather) | 1 | `renderWeather` -> `renderSnowAndRain`, `isFancyGraphicsOrBetter()` -> `useFancyGraphics()`, `graphicsMode().get()` |
| `ShaderProgramMixin.java` | 1 | `GlUniform` -> `Uniform`, `glRef` -> `programId`, `getUniformLocation` -> `glGetUniformLocation`, `bind` -> `apply` |
| `SpriteBillboardParticleMixin.java` | 2 | `buildGeometry()` -> `render()` |
| `ClientWorldMixin.java` (sky) | 1 | `getBiomeForNoiseGen()` -> `getBiomeManager().getNoiseBiomeAtQuart()` |
| `ColorSRGB.java` | 1 | `ColorHelper.Abgr.getAbgr()` -> `FastColor.ABGR32.color()` |
| `SpriteContentsMixin.java` | 1 | `nativeImage.width()` -> `getWidth()` |
| `BiomeMixin.java` | 3 | `getGrassColor()` -> `getGrassColorOverride()`, `getFoliageColor()` -> `getFoliageColorOverride()`, `getModifiedGrassColor()` -> `modifyColor()` |
| `WindowMixin.java` | 2 | `Util.getOperatingSystem()` -> `getPlatform()`, `Util.OperatingSystem` -> `Util.OS` |

**Wave 5 — Vertex format constants (4 files, 4 errors)**

| File | Old (Yarn) | New (Mojang) |
|------|-----------|-------------|
| `GlyphVertex.java` | `POSITION_COLOR_TEXTURE_LIGHT` | `POSITION_COLOR_TEX_LIGHTMAP` |
| `LineVertex.java` | `LINES` | `POSITION_COLOR_NORMAL` |
| `ModelVertex.java` | `POSITION_COLOR_TEXTURE_OVERLAY_LIGHT_NORMAL` | `NEW_ENTITY` |
| `ParticleVertex.java` | `POSITION_TEXTURE_COLOR_LIGHT` | `PARTICLE` |

---

## What's left (100 warnings, 0 errors)

The project compiles. `./gradlew compileJava` passes. But the mixin annotation processor spits out 100 warnings, and some of them are going to crash at runtime if they're not fixed. Here's the breakdown.

### Dangerous — @Shadow fields pointing at wrong names (32 "Cannot find target" + 32 "Unable to locate obfuscation mapping" = 64 warnings)

These @Shadow fields still use Yarn field names. The mixin AP can't find the field in the target class, which means the mixin will fail to apply at runtime and the game will crash on launch.

| File | Lines | Target class | # fields broken |
|------|-------|-------------|----------------|
| `GlyphRendererMixin.java` | 19, 23, 27, 31, 35, 39, 43, 47 | `BakedGlyph` | 8 |
| `FrustumMixin.java` | 15, 18, 21, 24 | `Frustum` | 4 |
| `PackedIntegerArrayMixin.java` | 18, 22, 26 | `SimpleBitStorage` | 3 |
| `BakedQuadMixin.java` | 22, 30, 34 | `BakedQuad` | 3 |
| `FramebufferMixin.java` (compositing) | 15, 18, 21 | `RenderTarget` | 3 |
| `OverlayVertexConsumerMixin.java` | 33, 37 | `SheetedDecalTextureGenerator` | 2 |
| `RenderLayersMixin.java` | 18, 23 | `ItemBlockRenderTypes` | 2 |
| `PlayerSkinTextureMixin.java` | 14, 17 | `HttpTexture` | 2 (1 field + 1 method) |
| `WeightedBakedModelMixin.java` | 17 | `WeightedBakedModel` | 1 |
| `MultipartBakedModelMixin.java` | 24 | `MultiPartBakedModel` | 1 |
| `LevelLoadingScreenMixin.java` | 31 | `LevelLoadingScreen` | 1 |
| `MatrixStackMixin.java` | 13 | `PoseStack` | 1 |
| `WindowMixin.java` (core) | 18 | `Window` | 1 |

Every one of these needs the Yarn field name looked up and replaced with the Mojang name. The fix for each is trivial — rename the field — but there are 32 of them.

### Probably dangerous — @Inject/@Redirect target descriptors with Yarn class paths (4 warnings)

These mixin target strings contain Yarn package paths in their method descriptors. The mixin AP can't resolve them, and they'll likely crash at runtime.

| File | Line | Problem |
|------|------|---------|
| `FramebufferMixin.java` (debug) | 20 | Target method `draw(IIZ)V` doesn't exist — Mojang name is `blitToScreen(int, int, boolean)V` |
| `NativeImageBackedTextureMixin.java` | 11 | Descriptor has `Lnet/minecraft/client/texture/NativeImage;` — should be `Lcom/mojang/blaze3d/platform/NativeImage;` |
| `RenderSystemMixin.java` (debug) | 30 | Descriptor has `Lnet/minecraft/util/ResourceLocation;` — should be `Lnet/minecraft/resources/ResourceLocation;` |
| `VertexBufferMixin.java` | 11 | Descriptor has `Lnet/minecraft/client/gl/ShaderInstance;` — should be `Lnet/minecraft/client/renderer/ShaderInstance;` |

### Probably harmless — "Unable to determine descriptor" (24 warnings)

The mixin AP can't verify the target method signature at compile time. This happens a lot with method-only `@Inject(method = "methodName")` annotations where the AP can't resolve overloads. Usually the refmap sorts it out at runtime. Most of these are probably fine, but some might hide a wrong method name.

Files affected: `MinecraftClientMixin.java` (3), `BlockColorsMixin.java` (1), `WorldRendererMixin.java` (core, 1), `ClientPlayNetworkHandlerMixin.java` (1), `PlayerSkinTextureMixin.java` (1), `OptionsScreenMixin.java` (1), `FramebufferMixin.java` (compositing, 1), `GlyphRendererMixin.java` (1), `BlockModelRendererMixin.java` (tracking, 1), `SpriteContentsAnimatorImplMixin.java` (2), `WindowMixin.java` (workarounds, 1), `AbstractTextureMixin.java` (2), `BufferRendererMixin.java` (1), `FramebufferMixin.java` (debug, 2), `SpriteContentsAnimatorImplMixin.java` (debug, 1), `VertexFormatMixin.java` (2), `DebugHudMixin.java` (1), `VertexConsumerProviderImmediateMixin.java` (1)

### Harmless — "Unable to locate method mapping" for LWJGL calls (5 warnings)

These target LWJGL methods (`glfwCreateWindow`, `GL.createCapabilities`, `RenderSystem.flipFrame`), which aren't Minecraft code and don't have obfuscation mappings. Expected. These are fine.

Files affected: `WindowMixin.java` (core, 1), `WindowMixin.java` (workarounds, 2), `WorldRendererMixin.java` (core, 1 — `Options.getClampedViewDistance`), `InGameHudMixin.java` (1 — `Minecraft.isFancyGraphicsOrBetter`)

### Harmless — "Unable to locate field mapping" (3 warnings)

Same idea — the AP can't find the obfuscation mapping for a field target in an `@At(FIELD)` expression.

Files: `CuboidMixin.java` (1 — `ModelPart$Cuboid;sides`), `RenderLayersMixin.java` (options, 1 — `fancyGraphicsOrBetter`), `SpriteContentsMixin.java` (mipmaps, 1 — `SpriteContents;image` — still uses Yarn path `net/minecraft/client/texture/SpriteContents`)

### Harmless — deprecated API usage (2 warnings, not counted individually)

The compiler notes "Some input files use or override a deprecated API" and "marked for removal". This is fine — Mojang deprecates stuff all the time in 1.20.x and it still works.

### Warning totals

| Category | Count | Will it crash? |
|----------|-------|---------------|
| @Shadow field name wrong | 64 (32 fields × 2 warnings each) | Yes — mixin apply fails |
| @Inject/@Redirect descriptor has Yarn paths | 4 | Yes — method not found |
| "Unable to determine descriptor" | 24 | Maybe — depends on refmap |
| LWJGL method mapping not found | 5 | No |
| Field mapping not found | 3 | Maybe — 1 has a Yarn path |
| Deprecated API | ~2 | No |
| **Total** | **~100** | |

---

## Game plan for the remaining fixes

**Step 1 — Fix the 32 @Shadow fields (kills 64 warnings, prevents launch crashes)**

Look up every @Shadow field name in the Forge decompiled sources and rename to Mojang. Highest priority — these are guaranteed crashes. The biggest offender is `GlyphRendererMixin.java` with 8 broken fields.

**Step 2 — Fix the 4 broken @Inject/@Redirect descriptors**

Replace Yarn class paths in the target strings with Mojang paths:
- `net/minecraft/client/texture/NativeImage` -> `com/mojang/blaze3d/platform/NativeImage`
- `net/minecraft/util/ResourceLocation` -> `net/minecraft/resources/ResourceLocation`
- `net/minecraft/client/gl/ShaderInstance` -> `net/minecraft/client/renderer/ShaderInstance`
- `draw(IIZ)V` -> `blitToScreen(II)V` (and check exact Mojang signature)

**Step 3 — Audit the 24 "Unable to determine descriptor" warnings**

Most are probably fine, but scan each one to make sure the method name is actually correct in Mojang mappings. The `method_19828` in `OptionsScreenMixin.java` is definitely still a Yarn intermediary name and needs to be looked up.

**Step 4 — Fix the 1 field mapping with a Yarn path**

`SpriteContentsMixin.java` line 41 — the `@At(FIELD)` target still has `net/minecraft/client/texture/SpriteContents` which should be `net/minecraft/client/renderer/texture/SpriteContents`.

**Step 5 — Runtime test**

Launch Minecraft with the built mod in a Forge 1.20.1 dev environment (`./gradlew runClient`). This is where we find out if:
- The remaining "Unable to determine descriptor" warnings are actually fine
- The mixin refmap resolves everything correctly
- There are runtime logic errors from incorrect Yarn->Mojang translations that compiled fine but do the wrong thing
- The access transformer entries all work

**Step 6 — Build a jar**

`./gradlew build` to produce a distributable jar for testing with Better MC.

---

## Files touched (424 total, all unstaged)

Everything is on branch `1.20.1/stable-0.5`, uncommitted.

- **3 build files**: `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`
- **~30 API sources**: `src/api/java/net/caffeinemc/mods/sodium/api/**`
- **~380 main sources**: `src/main/java/me/jellysquid/mods/sodium/**`
- **2 desktop sources**: `src/desktop/java/**`
- **3 resource files**: mods.toml, accesstransformer.cfg, pack.mcmeta
- **2 deleted files**: fabric.mod.json, sodium.accesswidener
- **1 utility**: `remap.sed`
- **116 files modified** since last commit (the method-level remapping pass)

---

## Things that could bite me later

1. **The sed script was a blunt instrument.** It renamed Sodium's own classes along with Minecraft's. I caught ~35 files, but there could be subtler damage hiding in the code that compiles fine but breaks at runtime.

2. **Mixin refmap might not resolve everything.** Even with 0 compile errors, the 24 "Unable to determine descriptor" warnings mean the mixin AP couldn't verify 24 targets at compile time. It's relying on the refmap to figure it out at runtime. If any of those method names are actually wrong, the mixin silently fails or crashes.

3. **`OptionsScreenMixin.java` still has `method_19828`** — that's a Yarn intermediary name, not even a human-readable name. Needs to be looked up in the Yarn mappings and translated to Mojang.

4. **`VertexConsumerProviderImmediateMixin.java` has `method_24213`** — same problem, still an intermediary name.

5. **Access Transformer might be missing entries.** The `accesstransformer.cfg` was written from the original `sodium.accesswidener`, but I haven't verified every single entry maps correctly. The CloudRenderer fix already needed one AT entry added.

6. **Forge-specific hooks aren't wired up yet.** Still need to deal with:
   - Forge event bus registration
   - `IForgeBlock`/`IForgeFluid` extensions
   - `RenderLevelStageEvent` vs Fabric's `WorldRenderEvents`
   - Forge's model loading differences

7. **`FlawlessFrames.java`** has a Fabric-only integration (FREX/Canvas). Probably needs to be gutted or replaced.

8. **`BlockEntity.getModelData()`** in `ClonedChunkSection.java` returns Forge's `ModelData` type, not `Object`. The code stores it as `Int2ReferenceMap<Object>` which might cause a ClassCastException downstream if anything expects a specific type.

9. **Zero runtime testing so far.** `./gradlew compileJava` passes. `./gradlew build` has not been run. No idea if it actually works in-game yet.
