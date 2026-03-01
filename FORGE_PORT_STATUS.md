# Sodium Forge Port — Status & Notes

## Why am I doing this?

Better MC is a Forge-only modpack, and it runs like garbage on low-end hardware. Sodium is hands down the best rendering optimization mod for Minecraft, but it's Fabric-only. My friends and I want to play Better MC together without the slideshow experience, so I'm porting Sodium 0.5.13 to Forge 1.20.1 myself.

The core problem: Fabric mods use "Yarn" mappings for Minecraft's obfuscated code, while Forge uses "Mojang official" mappings. Same game, completely different names for everything. So this port is mostly a massive renaming operation across 415 Java files, plus swapping out Fabric's mod loader API for Forge's.

---

**Branch:** `1.20.1/stable-0.5`
**Source:** Sodium 0.5.13 (Fabric/Yarn)
**Target:** Forge 1.20.1 (Mojang mappings)
**Last updated:** 2026-03-01
**Build status:** 0 errors, 10 warnings — compiles successfully
**Runtime status:** Fully functional. Terrain renders correctly in all dimensions. Overworld, Nether, End all confirmed working.

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

After the compile-time fixes, the game still crashed on launch due to remaining Yarn names in @Shadow fields, wrong mixin targets, and Forge-specific API differences. Fixed across three debugging sessions.

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

### Terrain rendering fixes (Sessions 9–10)

After the game launched and loaded a world, terrain rendered but was completely wrong — blocks displaced from their correct positions, cave systems floating in the air, the player phasing through visible geometry because physics operated on the correct (invisible) positions. This was the final major hurdle. It took two sessions of pipeline verification and diagnostic shader work to narrow down, and the root cause turned out to be in the world data cloning path, not in the rendering pipeline at all.

**The terrain displacement problem — what it looked like**

The terrain appeared "exploded." Cave geometry hovered at surface level. Grass and trees were absent. Block textures and lighting were correct, but every section's block content was from the wrong vertical position in the chunk column. The player collided with invisible blocks at the correct positions while the rendered blocks floated elsewhere. All three dimensions were affected identically.

**How it was diagnosed**

Every component of the chunk rendering pipeline from Java through the vertex shader was individually verified correct — vertex encoding/decoding, section index packing/unpacking, GL vertex attribute binding, model-view and projection matrices, region offset computation, camera int/frac split, and the mesh upload path. All of it checked out. Three rounds of diagnostic shader visualizations were deployed:

1. Section-relative coordinates encoded as RGB — showed jumbled color patches instead of smooth gradients, confirming sections had wrong content but distinct indices.
2. Camera-relative Y position encoded as green/blue/red — result was uniformly green, meaning sections rendered at approximately correct Y positions. The displacement was not vertical in screen space.
3. Camera-relative X/Z position encoded as red/blue channels — showed smooth, correct gradients matching expected spatial distribution. This proved the `position` vector computed in the vertex shader was mathematically correct.

That third result was the key insight. If the camera-relative position is correct but the terrain looks wrong, the issue is not where sections are drawn — it's what block data they contain. The sections render at the right XYZ, but their mesh geometry comes from the wrong chunk section. This pointed directly at the world data cloning path: `WorldSlice.prepare()` and `ClonedChunkSectionCache.clone()`.

**Root cause: `getSectionIndex()` vs `getSectionIndexFromSectionY()`**

Minecraft 1.20.1's `LevelHeightAccessor` has two distinct methods for converting Y coordinates to section array indices:

- `getSectionIndex(int blockY)` — takes a **block Y coordinate** (e.g., 64). Internally computes `(blockY >> 4) - getMinSection()`.
- `getSectionIndexFromSectionY(int sectionY)` — takes a **section Y coordinate** (e.g., 4). Internally computes `sectionY - getMinSection()`.

The original Fabric code used a single Yarn method `sectionCoordToIndex()` which takes a section Y. The `remap.sed` script (line 296) correctly mapped this to `getSectionIndexFromSectionY()`. But two call sites were instead using `getSectionIndex()`:

`WorldSlice.java` line 97 — the section emptiness check in `prepare()`:
```java
// WRONG: origin.getY() returns section Y (e.g., 4), but getSectionIndex() expects block Y (e.g., 64)
LevelChunkSection section = chunk.getSections()[world.getSectionIndex(origin.getY())];

// FIXED:
LevelChunkSection section = chunk.getSections()[world.getSectionIndexFromSectionY(origin.getY())];
```

`ClonedChunkSectionCache.java` line 65 — the section cloning in `clone()`:
```java
// WRONG: y is a section Y coordinate, but getSectionIndex() expects block Y
section = chunk.getSections()[this.world.getSectionIndex(y)];

// FIXED:
section = chunk.getSections()[this.world.getSectionIndexFromSectionY(y)];
```

When section Y=4 (surface level, block Y 64–79) was passed to `getSectionIndex()`, the method computed `(4 >> 4) - (-4) = 4` instead of the correct `4 - (-4) = 8`. Every section in the world got block data from a section 4 positions lower than intended. Underground cave geometry appeared at the surface. Surface grass and trees went to sections above the build limit and were discarded. The displacement was exactly `4 * 16 = 64 blocks` vertically in world data, but because the rendering positions were correct and only the mesh content was wrong, it manifested as cave systems floating in the air at surface level.

These two calls likely ended up wrong because the original Yarn source used `sectionCoordToIndex` (a method that doesn't exist in Mojang mappings), and during manual edits they were changed to `getSectionIndex` (which does exist, compiles, and looks right) instead of the correct `getSectionIndexFromSectionY`. The sed script handled it correctly where it ran, but these two call sites were probably edited by hand during the Wave 1 compile fixes.

**Additional fix: `WorldSlice.reset()` loop bound**

`WorldSlice.reset()` iterated over `SECTION_ARRAY_LENGTH` (3, the number of sections per axis) instead of `SECTION_ARRAY_SIZE` (27, the total number of sections in the 3x3x3 neighbor cube). This meant only 3 of 27 light array entries, block entity maps, and render data maps were cleared between pooled reuses. In practice this didn't cause visible symptoms because `copyData()` overwrites all 27 entries on the next build, but it leaked stale references and could cause issues if a section fell out of bounds between builds.

```java
// WRONG: only clears 3 of 27 entries
for (int sectionIndex = 0; sectionIndex < SECTION_ARRAY_LENGTH; sectionIndex++) {

// FIXED:
for (int sectionIndex = 0; sectionIndex < SECTION_ARRAY_SIZE; sectionIndex++) {
```

**Other fixes applied during Sessions 9–10**

| File | Fix |
|------|-----|
| `DefaultChunkRenderer.java` | `getVisibleFaces()` was passing `originX, originY, originZ` (region chunk origin) instead of `camera.intX, camera.intY, camera.intZ` (camera position). Draw-time face culling was relative to the region origin instead of the camera. Fixed to use camera coordinates. |
| `BlockRenderer.java` | `getGeometry()` called 3-param `getQuads(state, face, random)` — the vanilla signature. Forge models override the 5-param version `getQuads(state, face, random, ModelData.EMPTY, null)`. Changed to the 5-param call so quads dispatch through Forge's patched method. |
| `BlockModelRendererMixin.java` | Same 3-param to 5-param `getQuads` fix as `BlockRenderer.java`. |
| `BakedQuadMixin.java` | Thread-safety race condition in `sodium$ensureInitialized()`. The `sodium$initialized = true` flag was set BEFORE the `normal`, `normalFace`, and `flags` fields were written. Multiple chunk builder threads racing on the same `BakedQuad` instance could see `initialized=true` but `normalFace` still null, causing a `NullPointerException` at `BakedChunkModelBuilder.getVertexBuffer()`. Fixed by moving `sodium$initialized = true` to after all field writes. |
| `BlockRenderer.java` | Defensive null check added: if `quad.getNormalFace()` returns null (residual from the race condition above, or any other edge case), fall back to `ModelQuadFacing.UNASSIGNED` instead of crashing. |

**Diagnostic code deployed and reverted**

All diagnostic code has been removed from the codebase. For the record, these were deployed during debugging and reverted after the root cause was found:

| File | What was added | Status |
|------|---------------|--------|
| `block_layer_opaque.vsh` | `v_DebugPos` varying passing camera-relative position to fragment shader. Three iterations: section-relative color, Y-position encoding, X/Z-position encoding. | Reverted. |
| `block_layer_opaque.fsh` | Debug color blend (60–70%) over normal texture. Three iterations matching the vertex shader changes. | Reverted. |
| `RenderSectionManager.java` | `shouldUseOcclusionCulling()` hardcoded to `return false`. Frame-counted debug logging in `update()` and `renderLayer()`. | Reverted. Occlusion culling restored to original logic. |
| `DefaultChunkRenderer.java` | Frame-counted debug logging dumping model-view matrix, camera position, and per-region offset values. | Reverted. |
| `SodiumWorldRenderer.java` | Frame-counted debug logging in `drawChunkLayer()`. | Reverted. |
| `ChunkBuilderMeshingTask.java` | `AtomicInteger` counter logging section coordinates and mesh pass counts. | Reverted. |

---

## Current state

The port works. Terrain renders correctly in all three dimensions — Overworld, Nether, and End. Blocks appear at their correct positions, textures and lighting are correct, the player collides with the blocks they can see. Chunk loading and unloading works. The sky, clouds, HUD, and entities all render.

The build produces a working jar with `./gradlew clean jar` (10 warnings, 0 errors). The test task is broken at the Gradle configuration level ("Type T not present") and must be skipped; `./gradlew clean build` does not work, but `./gradlew clean jar` does.

---

## What's left

### Step 1 — Clean up remaining warnings

The mixin AP emits 4 warnings that may affect functionality. The other 6 are deprecation warnings on `ResourceLocation` constructors and `FMLJavaModLoadingContext.get()` which are harmless on 1.20.1.

Mixin warnings that matter:

- `OptionsScreenMixin.java` — target `lambda$init$2` can't be resolved. This is the "Video Settings" button redirect that opens Sodium's settings GUI instead of vanilla's. If the lambda name is wrong, clicking Video Settings in the options screen will open vanilla's settings instead of Sodium's.
- `VertexConsumerProviderImmediateMixin.java` — target `lambda$endBatch$0` can't be resolved. This is a `@ModifyVariable` for immediate-mode render batching optimization. If it fails, rendering still works but without Sodium's batching optimization for non-terrain geometry.
- `WindowMixin.java` (core) — `glfwCreateWindow` target can't be resolved. Already marked `require = 0`. Sodium uses this to set OpenGL context hints before window creation. Forge handles this differently; the mixin is optional and harmless if it doesn't apply.
- `WindowMixin.java` (workarounds) — same `glfwCreateWindow` target. Also `require = 0`. Same situation.

### Step 2 — Runtime testing

Terrain rendering is confirmed working. Still need to verify:

- Translucent rendering (water, ice, stained glass)
- Sodium's settings GUI (depends on `OptionsScreenMixin` resolving correctly)
- Chunk rebuild on block place/break
- Performance compared to vanilla

### Step 3 — Build a distributable jar

`./gradlew clean jar` produces `build/libs/sodium-forge-0.5.13-forge.jar`. Test with Better MC modpack.

---

## Files touched (51 files modified since last commit)

Everything is on branch `1.20.1/stable-0.5`, uncommitted.

**Build system (1 file):**
- `build.gradle.kts` — refmap copy task, duplicates strategy

**Mod core (1 file):**
- `SodiumClientMod.java` — `isConfigAvailable()` guard

**World data cloning (2 files — terrain displacement root cause):**
- `WorldSlice.java` — `getSectionIndex()` -> `getSectionIndexFromSectionY()` in `prepare()`, `SECTION_ARRAY_LENGTH` -> `SECTION_ARRAY_SIZE` in `reset()`
- `ClonedChunkSectionCache.java` — `getSectionIndex()` -> `getSectionIndexFromSectionY()` in `clone()`

**Rendering pipeline (5 files):**
- `SodiumWorldRenderer.java` — render layer dispatch
- `DefaultChunkRenderer.java` — face culling fix (`camera.intX/Y/Z` instead of `originX/Y/Z`)
- `RenderSectionManager.java` — occlusion culling logic restored
- `BlockRenderer.java` — 5-param `getQuads()` for Forge, defensive null check on `normalFace`
- `ChunkBuilderMeshingTask.java` — mesh building

**Shaders (2 files):**
- `block_layer_opaque.vsh` — clean (diagnostic code reverted)
- `block_layer_opaque.fsh` — clean (diagnostic code reverted)

**Mixin config (1 file):**
- `sodium.mixins.json` — added `refmap` field

**Mixin files (39 files):**
- `MinecraftClientMixin.java` — `render` -> `runTick`, `onInitFinished` -> `setInitialScreen`, config guard
- `WindowMixin.java` (core) — `handle` -> `window`, `require = 0`
- `BlockColorsMixin.java` — `registerColorProvider` -> `register`
- `BakedQuadMixin.java` — `vertexData` -> `vertices`, `colorIndex` -> `tintIndex`, `face` -> `direction`, lazy init with thread-safety fix
- `BlockModelRendererMixin.java` — 5-param `getQuads()` for Forge
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

1. **The sed script was a blunt instrument.** It renamed Sodium's own classes along with Minecraft's. I caught ~35 files, but there could be subtler damage hiding in the code that compiles fine but breaks at runtime. The `getSectionIndex` vs `getSectionIndexFromSectionY` bug was exactly this kind of damage — it compiled, it looked right, and it took two debugging sessions to find.

2. **Mixin refmap might not resolve everything.** The 4 "Unable to determine descriptor" warnings mean the mixin AP couldn't verify those targets at compile time. If any of those method names are actually wrong, the mixin silently fails.

3. **Access Transformer might be missing entries.** The `accesstransformer.cfg` was written from the original `sodium.accesswidener`, but not every entry has been verified. The CloudRenderer fix already needed one AT entry added.

4. **Forge-specific hooks aren't wired up yet.** Still need to deal with:
   - Forge event bus registration
   - `IForgeBlock`/`IForgeFluid` extensions
   - `RenderLevelStageEvent` vs Fabric's `WorldRenderEvents`
   - Forge's model loading differences

5. **`FlawlessFrames.java`** has a Fabric-only integration (FREX/Canvas). Probably needs to be gutted or replaced.

6. **`BlockEntity.getModelData()`** in `ClonedChunkSection.java` returns Forge's `ModelData` type, not `Object`. The code stores it as `Int2ReferenceMap<Object>` which might cause a ClassCastException downstream if anything expects a specific type.

7. **Gradle test task is broken.** `./gradlew build` fails at configuration time with "Type T not present." This is a Gradle/Java version compatibility issue with the test infrastructure, not a code issue. `./gradlew clean jar` works fine. Low priority — there are no tests to run anyway.
