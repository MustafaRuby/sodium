# Sodium Forge Port — Status & Notes

## Why am I doing this?

Better MC is a Forge-only modpack, and it runs like garbage on low-end hardware. Sodium is hands down the best rendering optimization mod for Minecraft, but it's Fabric-only. My friends and I want to play Better MC together without the slideshow experience, so I'm porting Sodium 0.5.13 to Forge 1.20.1 myself.

The core problem: Fabric mods use "Yarn" mappings for Minecraft's obfuscated code, while Forge uses "Mojang official" mappings. Same game, completely different names for everything. So this port is mostly a massive renaming operation across 415 Java files, plus swapping out Fabric's mod loader API for Forge's.

---

**Branch:** `1.20.1/stable-0.5`
**Source:** Sodium 0.5.13 (Fabric/Yarn)
**Target:** Forge 1.20.1 (Mojang mappings)
**Last updated:** 2026-03-01
**Build status:** 0 errors, 28 warnings — compiles successfully
**Runtime status:** Game launches, world loads, terrain renders incorrectly — "exploded" block positions

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

| File | Errors | Key renames |
|------|--------|------------|
| `FluidRenderer.java` | 19 | `getType()`, `Shapes.box()`, `Shapes.blockOccudes()`, `setWithOffset()`, `contents().height()`, `shouldRenderBackwardUpFace()`, `shouldDisplayFluidOverlay()`, `TextureAtlas.LOCATION_BLOCKS`, `above()`, `getOwnHeight()` |
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

### Runtime crash fixes (Sessions 6–8)

After the compile-time fixes, the game still crashed on launch due to remaining Yarn names in @Shadow fields, wrong mixin targets, and Forge-specific API differences. These were fixed across three debugging sessions.

**@Shadow field renames (39 files, 32 fields)**

Every @Shadow field that still used a Yarn name was looked up in Forge's decompiled sources and renamed. The full list is in the "Method-level remapping" tables above. The ones fixed at this stage that actually crashed at runtime:

| File | Yarn field | Mojang field |
|------|-----------|-------------|
| `FrustumMixin.java` | `x`, `y`, `z`, `frustumIntersection` | `camX`, `camY`, `camZ`, `intersection` |
| `WindowMixin.java` (core) | `handle` | `window` |
| `BakedQuadMixin.java` | `vertexData`, `colorIndex`, `face` | `vertices`, `tintIndex`, `direction` |
| `WeightedBakedModelMixin.java` | `models` | `list` |
| `MultipartBakedModelMixin.java` | `components` | `selectors` |
| `PackedIntegerArrayMixin.java` | `elementBits`, `maxValue`, `storage` | `bits`, `mask`, `data` |
| `GlyphRendererMixin.java` | 8 fields | All renamed to Mojang equivalents |
| `OverlayVertexConsumerMixin.java` | `affine`, `normalMatrix` | `cameraInversePose`, `normalInversePose` |
| `FramebufferMixin.java` (compositing) | `colorAttachment`, `depthAttachment`, `viewWidth` | `colorTextureId`, `depthBufferId`, `width` |
| `LevelLoadingScreenMixin.java` | `tracker` | `progressListener` |
| `MatrixStackMixin.java` | `stack` | `poseStack` |
| `RenderLayersMixin.java` | `layers`, `layersByFluid` | `TYPE_BY_BLOCK`, `TYPE_BY_FLUID` |
| `PlayerSkinTextureMixin.java` | `textureLoaded`, `close` | `uploaded`, `close` (method target rename) |

**@Inject/@Redirect target fixes**

| File | Old target | New target |
|------|-----------|-----------|
| `MinecraftClientMixin.java` | `method = "render"` (2 injections) | `method = "runTick"` |
| `MinecraftClientMixin.java` | `method = "onInitFinished"` | `method = "setInitialScreen"` |
| `BlockColorsMixin.java` | `method = "registerColorProvider"` | `method = "register"` |
| `WorldRendererMixin.java` (core) | `target = "...getClampedViewDistance()I"` | `target = "...getEffectiveRenderDistance()I"` |
| `WorldRendererMixin.java` (core) | `method = "render"` | `method = "renderLevel"` |
| `FramebufferMixin.java` (debug) | `draw(IIZ)V` | `blitToScreen(II)V` |
| `NativeImageBackedTextureMixin.java` | Yarn path in descriptor | Mojang path |
| `RenderSystemMixin.java` (debug) | Yarn path in descriptor | Mojang path |
| `VertexBufferMixin.java` | Yarn path in descriptor | Mojang path |

**Forge getQuads signature change**

Forge patches `BakedModel.getQuads()` from 3 parameters to 5 parameters. The two model @Overwrite mixins had to be updated to match Forge's signature, and marked `remap = false` since this is a Forge-added method.

| File | Old signature | New signature |
|------|-------------|-------------|
| `WeightedBakedModelMixin.java` | `getQuads(BlockState, Direction, RandomSource)` | `getQuads(BlockState, Direction, RandomSource, ModelData, RenderType)` |
| `MultipartBakedModelMixin.java` | `getQuads(BlockState, Direction, RandomSource)` | `getQuads(BlockState, Direction, RandomSource, ModelData, RenderType)` |

The `MultipartBakedModelMixin` also needed `MultipartModelData.resolve(modelData, model)` for Forge's multipart model data propagation.

**BakedQuadMixin lazy initialization**

Forge patches `BakedQuad` with additional constructors that Mixin's `@Inject(method = "<init>")` can't reliably target. The `@Inject` on `<init>` was removed and replaced with lazy initialization — Sodium's computed quad data (normal, normalFace, flags) is now calculated on first access via `sodium$ensureInitialized()` instead of in the constructor.

**SodiumClientMod.isConfigAvailable() guard**

`MinecraftClientMixin.preRender()` calls `SodiumClientMod.options()` which throws `IllegalStateException("Config not yet available")` if called before mod init completes. Added `isConfigAvailable()` check and early return.

**WindowMixin require = 0**

The `@Inject` targeting `glfwCreateWindow` in `WindowMixin` was made optional with `require = 0` because Forge's Window class structure differs enough that the injection point may not resolve.

**Mixin refmap wiring**

Added `"refmap": "sodium.refmap.json"` to `sodium.mixins.json`. Added a Gradle `copyRefmap` task to copy the mixin AP's generated refmap from `build/tmp/compileJava/` to `build/resources/main/` so it's on the classpath at runtime.

**Build system fixes**

Added `duplicatesStrategy = DuplicatesStrategy.EXCLUDE` to both `processResources` and `jar` tasks to prevent duplicate resource conflicts.

---

## Current state — the terrain rendering problem

The game launches, loads into a world, and renders terrain. Physics work (player collides with blocks correctly). The HUD, sky, entities, and particles all render. But the terrain itself is wrong.

### What it looks like

Blocks render with correct textures and lighting, but their positions are displaced. The terrain appears "exploded" — sections of blocks are shifted to wrong locations in 3D space. You can recognize grass, stone, trees, etc., but they're scattered rather than forming a coherent landscape. The player stands on invisible collision geometry while the visible blocks float elsewhere.

### What has been verified correct

Every component of the chunk rendering pipeline from Java through the vertex shader has been individually verified:

| Component | Status | How verified |
|-----------|--------|-------------|
| Vertex positions (Java side) | Correct | `BlockRenderer.writeGeometry()` outputs section-local coords (0-16 range) via `ctx.origin()` + quad position |
| CompactChunkVertex encoding | Correct | `(8.0 + pos) / 32.0` scaled to 20-bit uint. Shader decodes with `(uint * 32/1048576) - 8.0`. Math checks out. |
| Section index packing (Java) | Correct | `LocalSectionIndex.pack()`: X bits 5-7, Y bits 0-1, Z bits 2-4 |
| Section index unpacking (GLSL) | Correct | `_get_relative_chunk_coord()`: `>> uvec3(5,0,2) & uvec3(7,3,7)` — matches Java packing |
| Section index in vertex data | Correct | Packed into byte 3 of `a_LightAndData` attribute: `(section & 0xFF) << 24`, read as `a_LightAndData[3]` |
| GL vertex attribute binding | Correct | `glVertexAttribIPointer` used for integer attributes. `glBindAttribLocation` explicitly binds all 4 attributes. |
| Model-view matrix | Correct | Logged at runtime: row3 = (0,0,0,1) — rotation only, no translation. Camera transform is in u_RegionOffset, not the matrix. |
| Region offsets (u_RegionOffset) | Correct | Logged values match mathematical expectation: `(regionBlockOrigin - cameraIntPos) - cameraFracPos` |
| Camera int/frac split | Correct | `CameraTransform` splits camera position to integer + fractional. Logged values match. |
| Mesh upload pipeline | Correct | Traced through `ChunkMeshBufferBuilder` -> `StagingBuffer` -> GL buffer. Structurally sound. |
| Shader section translation | Correct | `u_RegionOffset + _get_draw_translation(_draw_id)` where `_get_draw_translation` = `relative_chunk_coord * 16.0` |

### What has been observed via diagnostics

**Test 1 — Occlusion culling disabled, face culling enabled:**
Terrain visible but displaced. More geometry visible than with occlusion culling on. Terrain appears "below feet, no grass visible, phasing through stuff."

**Test 2 — Occlusion culling disabled, ALL face culling disabled (both build-time and draw-time):**
Complete blackness. The entire view is a solid opaque mass. This is actually informative — it means the geometry IS forming a coherent opaque volume (positions are close enough that adjacent block faces overlap), but the interior faces overwhelm the visible surface.

**Test 3 — Shader debug visualization (section position encoded as color):**
Added `v_DebugSectionColor` varying that encodes `_get_relative_chunk_coord(_draw_id)` as RGB (R=X/7, G=Y/3, B=Z/7). Result: multiple distinct colors are visible, confirming that section indices are NOT all the same value. Sections have different indices. The color pattern does not form a smooth spatial gradient — it appears jumbled, suggesting sections are being assigned to wrong positions within their regions, or the render lists are matching sections to wrong region offsets.

### Diagnostic code currently in the codebase

**These must all be reverted before shipping.** They are marked with `// DIAGNOSTIC:` comments.

| File | What it does |
|------|-------------|
| `RenderSectionManager.java` | `shouldUseOcclusionCulling()` hardcoded to `return false`. Debug logging in `update()` (frames 0-20 and 50-80) and `renderLayer()` (first 30 calls). |
| `DefaultChunkRenderer.java` | Debug logging in `render()` — dumps model-view matrix and region offsets for first 3 render passes with geometry. |
| `SodiumWorldRenderer.java` | Debug logging in `drawChunkLayer()` — logs render layer and camera position for first 30 calls. |
| `ChunkBuilderMeshingTask.java` | Debug logging in `execute()` — logs section coordinates and mesh pass count for first 20 chunk builds. |
| `block_layer_opaque.vsh` | Passes `v_DebugSectionColor` varying to fragment shader, encoding section-relative coordinates as RGB. |
| `block_layer_opaque.fsh` | Blends 70% debug section color over the normal texture color. |

### Known bug introduced during diagnostics

`DefaultChunkRenderer.java` line 149 — the `getVisibleFaces()` call currently passes `originX, originY, originZ` (the region's chunk origin) instead of `camera.intX, camera.intY, camera.intZ` (the camera position). The original code used `camera.intX/Y/Z`. This makes draw-time face culling wrong (culling relative to region origin instead of camera), but this is NOT the root cause of the terrain displacement — the displacement was present before this change.

---

## What's left

### Step 1 — Identify the terrain displacement root cause

Everything that has been verified individually checks out. The positions encode correctly, the shader decodes correctly, the section indices pack/unpack correctly, the region offsets are mathematically correct. Yet the terrain is displaced.

The shader debug visualization shows distinct section colors that don't form a smooth gradient. This narrows the problem to one of:

1. **Section-to-region assignment is wrong.** A section might be assigned to the wrong region, so it gets the wrong `u_RegionOffset` but the right local section index — or vice versa. Check `RenderSection.getRegion()`, `RenderRegion.addSection()`, and the render list construction.

2. **The render list pairs the wrong section data with the wrong draw commands.** The iterator in `fillCommandBuffer` reads section indices and looks up mesh data pointers. If the section indices in the render list don't correspond to the mesh data in the storage, sections would draw at wrong positions. Check `ChunkRenderList` population and `SectionRenderDataStorage` indexing.

3. **Base vertex offsets in the multi-draw batch are wrong.** `multiDrawElementsBaseVertex` uses per-section base vertex offsets. If a section's vertex data was uploaded at a different offset than what the draw command references, the wrong vertices would be drawn with the wrong section translation. Check `SectionRenderDataUnsafe.getVertexOffset()` against actual upload positions.

4. **The 3-param vs 5-param getQuads mismatch.** `BlockRenderer.getGeometry()` calls `ctx.model().getQuads(state, face, random)` — the vanilla 3-param version. On Forge, the model's `@Overwrite` targets the 5-param version. If the 3-param call bypasses the overwritten method and falls through to different dispatch logic, blocks might return quads for the wrong model variant. Check whether `getQuads(state, face, random)` on Forge correctly dispatches to the 5-param overload.

### Step 2 — Fix the terrain displacement

Once the root cause is identified, fix it. This is the only blocker for functional terrain rendering.

### Step 3 — Revert all diagnostic code

Remove every line marked `// DIAGNOSTIC:` in the files listed above. Restore:
- `shouldUseOcclusionCulling()` to its original logic in `RenderSectionManager.java`
- All debug logging in `RenderSectionManager`, `DefaultChunkRenderer`, `SodiumWorldRenderer`, `ChunkBuilderMeshingTask`
- The shader debug visualization in `block_layer_opaque.vsh` and `block_layer_opaque.fsh`
- Fix `getVisibleFaces()` call to use `camera.intX/Y/Z` instead of `originX/Y/Z`

### Step 4 — Clean up remaining warnings

The mixin AP still emits ~28 warnings. Most are "Unable to determine descriptor" which the refmap handles at runtime. The ones that actually matter:

- `OptionsScreenMixin.java` still has `method_19828` — a Yarn intermediary name. Needs lookup.
- `VertexConsumerProviderImmediateMixin.java` has `method_24213` — same problem.
- `SpriteContentsMixin.java` (mipmaps) has a Yarn path in an `@At(FIELD)` target.

### Step 5 — Runtime testing

Once terrain renders correctly:
- Test with different biomes, structures, and underground
- Test chunk loading/unloading while moving
- Test translucent rendering (water, ice, stained glass)
- Test Sodium's settings GUI
- Test performance vs vanilla

### Step 6 — Build a jar

`./gradlew build` to produce a distributable jar for testing with Better MC.

---

## Files touched (51 files modified since last commit)

Everything is on branch `1.20.1/stable-0.5`, uncommitted.

**Build system (1 file):**
- `build.gradle.kts` — refmap copy task, duplicates strategy

**Mod core (1 file):**
- `SodiumClientMod.java` — `isConfigAvailable()` guard

**Rendering pipeline (5 files, includes diagnostic code):**
- `SodiumWorldRenderer.java` — debug logging
- `DefaultChunkRenderer.java` — debug logging + face culling bug (originX vs camera.intX)
- `RenderSectionManager.java` — occlusion culling disabled + debug logging
- `BlockRenderer.java` — face visibility check order change (functionally equivalent to original)
- `ChunkBuilderMeshingTask.java` — debug logging

**Shaders (2 files, diagnostic only):**
- `block_layer_opaque.vsh` — debug section color varying
- `block_layer_opaque.fsh` — debug color blend

**Mixin config (1 file):**
- `sodium.mixins.json` — added `refmap` field

**Mixin files (39 files):**
- `MinecraftClientMixin.java` — `render` -> `runTick`, `onInitFinished` -> `setInitialScreen`, config guard
- `WindowMixin.java` (core) — `handle` -> `window`, `require = 0`
- `BlockColorsMixin.java` — `registerColorProvider` -> `register`
- `BakedQuadMixin.java` — `vertexData` -> `vertices`, `colorIndex` -> `tintIndex`, `face` -> `direction`, lazy init
- `FrustumMixin.java` — `x/y/z` -> `camX/camY/camZ`, `frustumIntersection` -> `intersection`
- `OverlayVertexConsumerMixin.java` — `affine` -> `cameraInversePose`, `normalMatrix` -> `normalInversePose`
- `VertexConsumerProviderImmediateMixin.java` — target method rename
- `ChunkBuilderMixin.java` — target method rename
- `WorldRendererMixin.java` (core) — `getClampedViewDistance` -> `getEffectiveRenderDistance`, `render` -> `renderLevel`
- `PackedIntegerArrayMixin.java` — `elementBits` -> `bits`, `maxValue` -> `mask`, `storage` -> `data`
- `ClientPlayNetworkHandlerMixin.java` — target method rename
- `MultipartBakedModelMixin.java` — Forge 5-param getQuads, `components` -> `selectors`, `MultipartModelData.resolve()`
- `WeightedBakedModelMixin.java` — Forge 5-param getQuads, `models` -> `list`
- `LevelLoadingScreenMixin.java` — `tracker` -> `progressListener`
- `MatrixStackMixin.java` — `stack` -> `poseStack`
- `GlyphRendererMixin.java` — 8 @Shadow field renames
- `FramebufferMixin.java` (compositing) — `colorAttachment` -> `colorTextureId`, `depthAttachment` -> `depthBufferId`, `viewWidth` -> `width`
- `RenderLayersMixin.java` (model) — `layers` -> `TYPE_BY_BLOCK`, `layersByFluid` -> `TYPE_BY_FLUID`
- `CuboidMixin.java` — field target rename
- `PlayerSkinTextureMixin.java` — `textureLoaded` -> `uploaded`, method target rename
- 18 other mixin files — minor @Shadow, @Inject, and @Redirect target renames

---

## Things that could bite me later

1. **The sed script was a blunt instrument.** It renamed Sodium's own classes along with Minecraft's. I caught ~35 files, but there could be subtler damage hiding in the code that compiles fine but breaks at runtime.

2. **Mixin refmap might not resolve everything.** The 24 "Unable to determine descriptor" warnings mean the mixin AP couldn't verify 24 targets at compile time. If any of those method names are actually wrong, the mixin silently fails or crashes.

3. **`OptionsScreenMixin.java` still has `method_19828`** — a Yarn intermediary name. Needs to be looked up and translated to Mojang.

4. **`VertexConsumerProviderImmediateMixin.java` has `method_24213`** — same problem.

5. **Access Transformer might be missing entries.** The `accesstransformer.cfg` was written from the original `sodium.accesswidener`, but not every entry has been verified. The CloudRenderer fix already needed one AT entry added.

6. **Forge-specific hooks aren't wired up yet.** Still need to deal with:
   - Forge event bus registration
   - `IForgeBlock`/`IForgeFluid` extensions
   - `RenderLevelStageEvent` vs Fabric's `WorldRenderEvents`
   - Forge's model loading differences

7. **`FlawlessFrames.java`** has a Fabric-only integration (FREX/Canvas). Probably needs to be gutted or replaced.

8. **`BlockEntity.getModelData()`** in `ClonedChunkSection.java` returns Forge's `ModelData` type, not `Object`. The code stores it as `Int2ReferenceMap<Object>` which might cause a ClassCastException downstream if anything expects a specific type.

9. **BlockRenderer.getGeometry() calls 3-param getQuads.** Forge models override the 5-param version. The 3-param call may not dispatch through the Forge-patched method, which could cause blocks to return wrong or missing quads. This is a suspect for the terrain rendering issue.
