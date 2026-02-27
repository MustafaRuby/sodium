# Sodium Forge Port Status Report

**Branch:** `1.20.1/stable-0.5`
**Base:** Sodium 0.5.13 (Fabric, Yarn mappings)
**Target:** Forge 1.20.1 (Mojang official mappings)
**Date:** 2026-02-27
**Build status:** DOES NOT COMPILE (100 errors, 100 warnings)

---

## 1. WHAT HAS BEEN COMPLETED

### 1.1 Build System Conversion (Session 1)

| File | Change |
|------|--------|
| `build.gradle.kts` | Replaced Fabric Loom with ForgeGradle + MixinGradle. Uses `mappings("official", "1.20.1")`, `minecraft "net.minecraftforge:forge:1.20.1-47.3.0"`. |
| `settings.gradle.kts` | Added ForgeGradle + MixinGradle plugin repositories (maven.minecraftforge.net, SpongePowered). |
| `gradle.properties` | Updated for ForgeGradle properties. |

### 1.2 Forge Metadata Files (Session 1)

| File | Status |
|------|--------|
| `src/main/resources/META-INF/mods.toml` | CREATED. Forge mod descriptor replacing `fabric.mod.json`. |
| `src/main/resources/META-INF/accesstransformer.cfg` | CREATED. Replaces `sodium.accesswidener`. |
| `src/main/resources/pack.mcmeta` | CREATED. Resource pack metadata. |
| `src/main/resources/fabric.mod.json` | DELETED. |
| `src/main/resources/sodium.accesswidener` | DELETED. |

### 1.3 Fabric API to Forge API Conversions (Session 1)

6 Java files were converted from Fabric API to Forge API:

| File | Key Changes |
|------|-------------|
| `SodiumClientMod.java` | `ModInitializer` -> `@Mod("sodium")` + `FMLJavaModLoadingContext`. `FabricLoader` -> `ModList`. `Text.translatable()` -> `Component.translatable()`. |
| `MixinConfig.java` | `FabricLoader.getInstance()` -> `ModList.get()`. `ModContainer` -> `IModInfo`. |
| `SodiumPreLaunch.java` | Converted from Fabric `PreLaunchEntrypoint` to static initializer callable from mod constructor. |
| `FingerprintMeasure.java` | `FabricLoader` path resolution -> `ModList`/`FMLPaths`. |
| `HashedFingerprint.java` | Same Fabric -> Forge loader API changes. |
| `FluidRenderer.java` | `FluidRenderHandler` (Fabric) -> `IClientFluidTypeExtensions` (Forge). Complete rewrite of fluid color/sprite lookup. |
| `DefaultColorProviders.java` | Added `ForgeFluidAdapter` using `IClientFluidTypeExtensions.getTintColor()`. |

### 1.4 Yarn-to-Mojang Name Remapping (Session 2)

A comprehensive `remap.sed` script with ~200 patterns was created and applied to all 415 Java source files in a single pass:

```
find src -name "*.java" -type f -print0 | xargs -0 sed -i -f remap.sed
```

**Phase 1 — Import path remapping (~120 patterns):**

| Yarn Package | Mojang Package |
|--------------|----------------|
| `net.minecraft.client.render.*` | `net.minecraft.client.renderer.*` |
| `net.minecraft.client.render.model.*` | `net.minecraft.client.resources.model.*` |
| `net.minecraft.client.render.chunk.*` | `net.minecraft.client.renderer.chunk.*` |
| `net.minecraft.client.texture.*` | `net.minecraft.client.renderer.texture.*` |
| `net.minecraft.client.gui.screen.*` | `net.minecraft.client.gui.screens.*` |
| `net.minecraft.client.gui.widget.*` | `net.minecraft.client.gui.components.*` |
| `net.minecraft.client.option.*` | `net.minecraft.client.*` (Options) |
| `net.minecraft.util.math.*` | `net.minecraft.core.*` / `net.minecraft.world.phys.*` |
| `net.minecraft.util.Identifier` | `net.minecraft.resources.ResourceLocation` |
| `net.minecraft.block.*` | `net.minecraft.world.level.block.*` |
| `net.minecraft.fluid.*` | `net.minecraft.world.level.material.*` |
| `net.minecraft.world.chunk.*` | `net.minecraft.world.level.chunk.*` |
| `net.minecraft.world.biome.*` | `net.minecraft.world.level.biome.*` |
| `net.minecraft.text.*` | `net.minecraft.network.chat.*` |
| `net.minecraft.nbt.*` | `net.minecraft.nbt.*` (same) |
| `net.minecraft.util.math.random.*` | `net.minecraft.util.*` |
| `net.minecraft.util.registry.*` | `net.minecraft.core.registries.*` |

**Phase 2 — Class name remapping in code body (~50 patterns):**

| Yarn Class | Mojang Class |
|------------|--------------|
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
| ... and ~30 more | |

**Phase 3 — Method name remapping (~30 patterns):**

| Yarn Method | Mojang Method |
|-------------|---------------|
| `.getInstance()` on MinecraftClient | `.getInstance()` (same) |
| `.getWindow()` | `.getWindow()` (same) |
| `.textRenderer` | `.font` |
| `.drawTextWithShadow()` | `.drawString()` |
| `.getWidth()` on Text | `.width()` |
| `.isSame()` | `.is()` (on Fluid) |
| `.getU()` / `.getV()` | `.getU()` / `.getV()` (same on Sprite) |
| `.getMinU/V()` / `.getMaxU/V()` | `.getU0/V0()` / `.getU1/V1()` |
| `.defaultBlockState()` | `.defaultBlockState()` (same) |
| `.canOcclude()` | `.canOcclude()` (same) |

### 1.5 Post-Remap Fixes (Session 2)

**Phase 2 caused unintended renames of Sodium's OWN classes.** The bare `sed` patterns like `s|GameOptions|Options|g` renamed internal Sodium classes. These were manually reverted in ~35 files:

| File | Broken Name | Reverted To |
|------|-------------|-------------|
| `SodiumGameOptions.java` | `SodiumOptions` | `SodiumGameOptions` |
| `SodiumOptionsGUI.java` | `SodiumGameOptionsGUI` | `SodiumOptionsGUI` |
| `SodiumOptionsStorage.java` | `SodiumGameOptionsStorage` | `SodiumOptionsStorage` |
| `SodiumWorldRenderer.java` | `SodiumLevelRenderer` | `SodiumWorldRenderer` |
| `ChunkBuilder.java` (Sodium's own) | `ChunkRenderDispatcher` | `ChunkBuilder` |
| `FlatButtonWidget.java` | `FlatButton` | `FlatButtonWidget` |
| 29 mixin files | Various Mojang names | Original Yarn-based class names matching filenames |

**Additional targeted fixes applied:**
- `Text` -> `Component` in remaining GUI files
- `Element` -> `GuiEventListener`
- `StringVisitable` -> `FormattedText`
- `Sprite` -> `TextureAtlasSprite` (with word boundaries)
- `ReadableContainer` -> `PalettedContainerRO`
- `BlockPos.Mutable` -> `BlockPos.MutableBlockPos`
- `SpriteAtlasTexture` -> `TextureAtlas`
- `TextureAtlas.BLOCK_ATLAS_TEXTURE` constant usage
- Missing explicit imports added (e.g., `BoundingBox`, `PathPackResources`)

**Mixin string-based targets fixed:**
| File | Old Target | New Target |
|------|-----------|------------|
| `OutlineVertexConsumerMixin.java` | `net/minecraft/client/render/OutlineMultiBufferSource$OutlineVertexConsumer` | `net/minecraft/client/renderer/OutlineBufferSource$EntityOutlineGenerator` |
| `VertexConsumersMixin.java` | `net/minecraft/client/render/VertexMultiConsumer$Dual` | `com/mojang/blaze3d/vertex/VertexMultiConsumer$Double` |
| `VertexConsumersMixin.java` | `net/minecraft/client/render/VertexMultiConsumer$Union` | `com/mojang/blaze3d/vertex/VertexMultiConsumer$Multiple` |

---

## 2. WHAT REMAINS TO BE DONE (100 compile errors)

### 2.1 "cannot find symbol" — Wrong Class Names (need Yarn->Mojang lookup)

These are Yarn class/inner-class names still in code that need the correct Mojang equivalent:

| # | Yarn Name | Mojang Name | Files Affected | Error Count |
|---|-----------|-------------|----------------|-------------|
| 1 | `PoseStack.Entry` | `PoseStack.Pose` | BakedModelEncoder.java, EntityRenderer.java, BufferBuilderMixin.java (intrinsics), MatrixStackMixin.java, BlockModelRendererMixin.java (x2), ItemRendererMixin.java, EntityRenderDispatcherMixin.java (x2), BlockModelRendererMixin.java (tracking) | **15** |
| 2 | `BiomeEffects` | `BiomeSpecialEffects` | BiomeMixin.java (lines 16, 38) | **2** |
| 3 | `Biome.Weather` | `Biome.ClimateSettings` | BiomeMixin.java (line 20) | **1** |
| 4 | `CubicSampler.RgbFetcher` | `CubicSampler.ColorFetcher` | BackgroundRendererMixin.java, ClientWorldMixin.java (sky) | **2** |
| 5 | `CameraSubmersionType` | `FogRenderer.FogMode` (or check correct name) | WorldRendererMixin.java (sky, line 10) | **1** |
| 6 | `SheetedDecalTextureGenerator` | Needs lookup — may be wrong package or name | OverlayVertexConsumerMixin.java, DirectionMixin.java (x2) | **3** |
| 7 | `BakedQuadFactory` | `FaceBakery` | DirectionMixin.java (line 5) | **1** |
| 8 | `Chunk` | `LevelChunk` | EntityRenderDispatcherMixin.java (line 39) | **1** |
| 9 | `World` | `Level` | ClientWorldMixin.java (biome, line 28) | **1** |
| 10 | `ClientLevel.Properties` | `ClientLevel.ClientLevelData` | ClientWorldMixin.java (biome, line 27) | **1** |
| 11 | `Text` | `Component` | OptionsScreenMixin.java (line 15) | **1** |
| 12 | `ChunkProgressListener` | `ChunkProgressListener` (wrong package: needs `net.minecraft.server.level.progress`) | LevelLoadingScreenMixin.java (lines 11, 50) | **2** |
| 13 | `Weighted` / `net.minecraft.util.collection` | `WeightedEntry` in `net.minecraft.util.random` | WeightedBakedModelMixin.java (lines 7, 19, 42) | **3** |
| 14 | `RunArgs` | `GameConfig` | MinecraftClientMixin.java (line 82) | **1** |
| 15 | `ChunkData` | `ClientboundLevelChunkPacketData` | ClientChunkManagerMixin.java (line 50) | **1** |
| 16 | `LightData` | `ClientboundLightUpdatePacketData` | ClientPlayNetworkHandlerMixin.java (line 24) | **1** |
| 17 | `DefaultedVertexConsumer` | Needs lookup (may be correct name, wrong import) | BufferBuilderMixin.java (consumer, line 30) | **1** |
| 18 | `RenderCall` | `RenderCall` in `com.mojang.blaze3d.pipeline` (check package) | RenderSystemMixin.java (lines 3, 21) | **2** |
| 19 | `PalettedContainer` (self-ref) | Generic issue — `PalettedContainer` references itself | PalettedContainerMixin.java (line 21) | **1** |

### 2.2 "cannot find symbol" — Missing Imports

These classes exist in Mojang mappings but the import statement points to the wrong package:

| # | Class | Wrong Import | Correct Import | Files |
|---|-------|-------------|----------------|-------|
| 1 | `BlockDestructionProgress` | Missing entirely | `net.minecraft.server.level.BlockDestructionProgress` | SodiumWorldRenderer.java, WorldRendererMixin.java | **5** |
| 2 | `Camera` | Missing entirely | `net.minecraft.client.Camera` | SodiumWorldRenderer.java, WorldRendererMixin.java | **4** |
| 3 | `Frustum` | Missing entirely | `net.minecraft.client.renderer.culling.Frustum` | WorldRendererMixin.java | **1** |
| 4 | `BufferBuilder` | Missing entirely | `com.mojang.blaze3d.vertex.BufferBuilder` | CloudRenderer.java | **1** |
| 5 | `BlockState` | Missing entirely | `net.minecraft.world.level.block.state.BlockState` | LeavesBlockMixin.java | **2** |
| 6 | `VertexFormat` / `VertexFormat.Mode` | Wrong package ref | `com.mojang.blaze3d.vertex.VertexFormat` | BufferBuilderMixin.java (consumer) | **2** |
| 7 | `MutableBlockPos` | Wrongly imported from `org.spongepowered.asm.mixin` | Needs removal — use `BlockPos.MutableBlockPos` | RenderLayersMixin.java, SpriteContentsMixin.java | **2** |

### 2.3 "Unable to locate obfuscation mapping for @Overwrite method" (16 errors)

These mixin methods have Yarn names. They must be renamed to the Mojang method name of the target class.

| File | Line | Current Method Name (Yarn) | Target Class | Mojang Name (needs lookup) |
|------|------|---------------------------|--------------|---------------------------|
| `WorldRendererMixin.java` (core) | 79 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 88 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 102 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 117 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 136 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 145 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 154 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 163 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 172 | needs reading | `LevelRenderer` | TBD |
| `WorldRendererMixin.java` (core) | 197 | needs reading | `LevelRenderer` | TBD |
| `AsyncTextureMixin.java` | 17 | needs reading | `SimplePreparableReloadListener` | TBD |
| `TextureManagerMixin.java` | 22 | needs reading | `TextureManager` | TBD |
| `LevelLoadingScreenMixin.java` | 50 | needs reading | `LevelLoadingScreen` | TBD |
| `ModelPartMixin.java` | 103 | needs reading | `ModelPart` | TBD |
| `BufferBuilderMixin.java` (sorting) | 47 | needs reading | `BufferBuilder` | TBD |
| `BufferBuilderMixin.java` (sorting) | 76 | needs reading | `BufferBuilder` | TBD |
| `DirectionMixin.java` | 32 | needs reading | `Direction` / `FaceBakery` | TBD |
| `MatrixStackMixin.java` | 26 | needs reading | `PoseStack` | TBD |
| `MatrixStackMixin.java` | 49 | needs reading | `PoseStack` | TBD |
| `SpriteContentsInterpolationMixin.java` | 42 | needs reading | `SpriteContents$Interpolation` | TBD |
| `MipmapHelperMixin.java` | 41 | needs reading | `MipmapGenerator` | TBD |
| `BiomeMixin.java` | 71 | needs reading | `Biome` | TBD |

### 2.4 "Unable to locate obfuscation mapping for @Inject/@Redirect target" (11 errors)

| File | Line | Annotation | Current Target (Yarn) | Target Class | Mojang Name (needs lookup) |
|------|------|-----------|----------------------|--------------|---------------------------|
| `MinecraftClientMixin.java` | 89 | @Inject | `reloadResources` | `Minecraft` | `reloadResourcePacks` (?) |
| `WorldRendererMixin.java` (core) | 176 | @Inject | `reload` | `LevelRenderer` | `allChanged` |
| `WorldRendererMixin.java` (core) | 52 | @Redirect | `reload` | `LevelRenderer` | `allChanged` |
| `ModelPartMixin.java` | 85 | @Inject | `render` | `ModelPart` | `render` (same? check desc) |
| `WorldRendererMixin.java` (outlines) | 29 | @Inject | `drawBox` | `LevelRenderer` | `renderLineBox` (?) |
| `BlockModelRendererMixin.java` | 37 | @Inject | `render` | `ModelBlockRenderer` | `tesselateBlock` (?) |
| `WorldRendererMixin.java` (clouds) | 43 | @Inject | `reload` | `LevelRenderer` | `allChanged` |
| `WorldRendererMixin.java` (clouds) | 50 | @Inject | `reload` | `LevelRenderer` | `allChanged` |
| `WorldRendererMixin.java` (sky) | 33 | @Inject | `renderSky` | `LevelRenderer` | `renderSky` (check desc) |
| `DrawContextMixin.java` | 13, 22 | @Inject | `drawSprite` | `GuiGraphics` (?) | TBD |
| `SpriteBillboardParticleMixin.java` | 29 | @Inject | `setSprite` | `TextureSheetParticle` | `setSprite` (?) |

### 2.5 "Could not locate @Accessor target" (5 errors)

These field names are in Yarn mappings. Need the Mojang/SRG field name.

| File | Line | Yarn Field Name | Target Class | Mojang Field (needs lookup) |
|------|------|-----------------|--------------|-----------------------------|
| `NativeImageAccessor.java` | 9 | `pointer` | `NativeImage` | `pixels` (?) |
| `SpriteContentsAccessor.java` | 10 | `mipmapLevelsImages` | `SpriteContents` | `byMipLevel` (?) |
| `SpriteContentsAnimationAccessor.java` | 14 | `frameCount` | `SpriteContents$AnimatedTexture` | TBD |
| `SpriteContentsAnimatorImplAccessor.java` | 9 | `animation` | `SpriteContents$Ticker` | `animationInfo` (?) |
| `SpriteContentsAnimatorImplAccessor.java` | 15 | `currentTime` | `SpriteContents$Ticker` | `frame` / `subFrame` (?) |

### 2.6 "Mixin has no targets" (2 errors)

| File | Line | Issue |
|------|------|-------|
| `BufferBuilderMixin.java` (consumer) | 29 | `@Mixin` target class not found. Likely `BufferBuilder` moved to `com.mojang.blaze3d.vertex`. Check import. |
| `OverlayVertexConsumerMixin.java` | 27 | `@Mixin` target class not found. `SheetedDecalTextureGenerator` — wrong class name or package. |

---

## 3. ERROR SUMMARY TABLE

| Error Category | Count | Difficulty |
|----------------|-------|-----------|
| `cannot find symbol` — wrong class/inner class name | ~35 | Easy (lookup + rename) |
| `cannot find symbol` — missing/wrong import | ~17 | Easy (add/fix imports) |
| `@Overwrite` method name wrong | ~16 | Medium (lookup Mojang method names) |
| `@Inject/@Redirect` target wrong | ~11 | Medium (lookup Mojang method names) |
| `@Accessor` field name wrong | 5 | Medium (lookup SRG/Mojang field names) |
| `Mixin has no targets` | 2 | Medium (fix target class reference) |
| **TOTAL** | **~100** | |

---

## 4. RECOMMENDED APPROACH FOR REMAINING FIXES

### Step 1: Fix all "cannot find symbol" errors (~52 errors)
These are straightforward class name and import fixes. Many are the same issue repeated (e.g., `PoseStack.Entry` -> `PoseStack.Pose` fixes 15 errors at once).

**Quick wins (fixes ~40 errors with <10 changes):**
1. `PoseStack.Entry` -> `PoseStack.Pose` globally (15 errors)
2. Add missing imports for `Camera`, `BlockDestructionProgress`, `Frustum`, `BufferBuilder`, `BlockState` (12 errors)
3. `BiomeEffects` -> `BiomeSpecialEffects` (2 errors)
4. `Biome.Weather` -> `Biome.ClimateSettings` (1 error)
5. `CubicSampler.RgbFetcher` -> `CubicSampler.ColorFetcher` (2 errors)
6. Remove bad `MutableBlockPos` imports from mixin package (2 errors)
7. Fix `Weighted` -> `WeightedEntry` + package (3 errors)
8. Fix `RunArgs` -> `GameConfig`, `ChunkData` -> inner class, `LightData` -> inner class (3 errors)

### Step 2: Fix Mixin method/field mappings (~34 errors)
Use https://linkie.shedaniel.me/ or Mojang mapping files to look up:
- All `@Overwrite` method Yarn->Mojang names
- All `@Inject`/`@Redirect` target Yarn->Mojang names
- All `@Accessor` field Yarn->Mojang names

### Step 3: Fix 2 remaining Mixin target issues
- Check `BufferBuilder` Mixin target import path
- Look up correct Mojang name for `SheetedDecalTextureGenerator`

### Step 4: Address warnings, test at runtime
- Fix the 100 warnings (mostly unused imports, unchecked casts)
- Runtime test in Minecraft to check mixins actually apply

---

## 5. FILES MODIFIED (424 total unstaged changes)

All changes are currently **UNSTAGED** in git on branch `1.20.1/stable-0.5`.

### Categories:
- **3 build files**: `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`
- **~30 API source files**: `src/api/java/net/caffeinemc/mods/sodium/api/**`
- **~380 main source files**: `src/main/java/me/jellysquid/mods/sodium/**`
- **2 desktop source files**: `src/desktop/java/**`
- **3 resource files**: `META-INF/mods.toml`, `META-INF/accesstransformer.cfg`, `pack.mcmeta`
- **2 deleted files**: `fabric.mod.json`, `sodium.accesswidener`
- **1 utility file**: `remap.sed`

---

## 6. KNOWN RISKS AND CAVEATS

1. **The `remap.sed` script was destructive.** Phase 2 bare string replacements renamed Sodium's own class names. ~35 files had to be manually reverted. There may be MORE subtle renames hiding in the code that don't cause compile errors but produce wrong behavior at runtime.

2. **Mixin targets were written for Fabric Yarn mappings.** Even after fixing compile errors, runtime behavior depends on mixins applying correctly to the right methods. ForgeGradle with `mappings("official", "1.20.1")` expects method names in Mojang mapping space.

3. **Access Transformer may be incomplete.** The `accesstransformer.cfg` was created in session 1 but may not cover all fields/methods that the original `sodium.accesswidener` provided access to.

4. **Forge-specific hooks are not yet implemented.** Things like:
   - Forge event bus registration for client events
   - `IForgeBlock`/`IForgeFluid` extensions
   - Forge's `RenderLevelStageEvent` vs Fabric's `WorldRenderEvents`
   - Forge's model loading system differences

5. **The `FlawlessFrames.java` file** references `FlawlessFrames` integration which was Fabric-specific (FREX/Canvas). May need Forge equivalent or removal.

6. **No runtime testing has been done.** Only `compileJava` has been attempted.
