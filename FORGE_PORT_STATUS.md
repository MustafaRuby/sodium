# Sodium Forge Port — Status & Notes

## Why am I doing this?

Better MC is a Forge-only modpack, and it runs like garbage on low-end hardware. Sodium is hands down the best rendering optimization mod for Minecraft, but it's Fabric-only. My friends and I want to play Better MC together without the slideshow experience, so I'm porting Sodium 0.5.13 to Forge 1.20.1 myself.

The core problem: Fabric mods use "Yarn" mappings for Minecraft's obfuscated code, while Forge uses "Mojang official" mappings. Same game, completely different names for everything. So this port is mostly a massive renaming operation across 415 Java files, plus swapping out Fabric's mod loader API for Forge's.

---

**Branch:** `1.20.1/stable-0.5`
**Source:** Sodium 0.5.13 (Fabric/Yarn)
**Target:** Forge 1.20.1 (Mojang mappings)
**Last updated:** 2026-02-27
**Build status:** 100 errors, 100 warnings — does not compile yet

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

---

## What's left (100 compile errors)

### Wrong class/inner class names — still using Yarn names

| # | Still says (Yarn) | Should be (Mojang) | Where | Errors |
|---|-------------------|--------------------|-------|--------|
| 1 | `PoseStack.Entry` | `PoseStack.Pose` | BakedModelEncoder, EntityRenderer, BufferBuilderMixin, MatrixStackMixin, BlockModelRendererMixin (x2), ItemRendererMixin, EntityRenderDispatcherMixin (x2), BlockModelRendererMixin (tracking) | **15** |
| 2 | `BiomeEffects` | `BiomeSpecialEffects` | BiomeMixin | **2** |
| 3 | `Biome.Weather` | `Biome.ClimateSettings` | BiomeMixin | **1** |
| 4 | `CubicSampler.RgbFetcher` | `CubicSampler.ColorFetcher` | BackgroundRendererMixin, ClientWorldMixin (sky) | **2** |
| 5 | `CameraSubmersionType` | needs lookup (maybe `FogRenderer.FogMode`?) | WorldRendererMixin (sky) | **1** |
| 6 | `SheetedDecalTextureGenerator` | needs lookup — wrong package or name | OverlayVertexConsumerMixin, DirectionMixin (x2) | **3** |
| 7 | `BakedQuadFactory` | `FaceBakery` | DirectionMixin | **1** |
| 8 | `Chunk` | `LevelChunk` | EntityRenderDispatcherMixin | **1** |
| 9 | `World` | `Level` | ClientWorldMixin (biome) | **1** |
| 10 | `ClientLevel.Properties` | `ClientLevel.ClientLevelData` | ClientWorldMixin (biome) | **1** |
| 11 | `Text` | `Component` | OptionsScreenMixin | **1** |
| 12 | `ChunkProgressListener` | same name, wrong package (`net.minecraft.server.level.progress`) | LevelLoadingScreenMixin | **2** |
| 13 | `Weighted` | `WeightedEntry` in `net.minecraft.util.random` | WeightedBakedModelMixin | **3** |
| 14 | `RunArgs` | `GameConfig` | MinecraftClientMixin | **1** |
| 15 | `ChunkData` | `ClientboundLevelChunkPacketData` | ClientChunkManagerMixin | **1** |
| 16 | `LightData` | `ClientboundLightUpdatePacketData` | ClientPlayNetworkHandlerMixin | **1** |
| 17 | `DefaultedVertexConsumer` | needs lookup (maybe correct name, wrong import?) | BufferBuilderMixin (consumer) | **1** |
| 18 | `RenderCall` | same name, check package (`com.mojang.blaze3d.pipeline`?) | RenderSystemMixin | **2** |
| 19 | `PalettedContainer` self-ref | generic type issue | PalettedContainerMixin | **1** |

### Missing or wrong imports

| Class | Problem | Correct import | Files | Errors |
|-------|---------|---------------|-------|--------|
| `BlockDestructionProgress` | Not imported | `net.minecraft.server.level.BlockDestructionProgress` | SodiumWorldRenderer, WorldRendererMixin | **5** |
| `Camera` | Not imported | `net.minecraft.client.Camera` | SodiumWorldRenderer, WorldRendererMixin | **4** |
| `Frustum` | Not imported | `net.minecraft.client.renderer.culling.Frustum` | WorldRendererMixin | **1** |
| `BufferBuilder` | Not imported | `com.mojang.blaze3d.vertex.BufferBuilder` | CloudRenderer | **1** |
| `BlockState` | Not imported | `net.minecraft.world.level.block.state.BlockState` | LeavesBlockMixin | **2** |
| `VertexFormat` | Wrong package | `com.mojang.blaze3d.vertex.VertexFormat` | BufferBuilderMixin (consumer) | **2** |
| `MutableBlockPos` | Imported from `org.spongepowered.asm.mixin` (wrong!) | Just use `BlockPos.MutableBlockPos` | RenderLayersMixin, SpriteContentsMixin | **2** |

### @Overwrite methods with Yarn names (16 errors)

These mixin methods override vanilla methods but still use Yarn method names. Each one needs to be looked up and renamed to the Mojang equivalent.

| File | Line | Target class |
|------|------|-------------|
| `WorldRendererMixin.java` (core) | 79, 88, 102, 117, 136, 145, 154, 163, 172, 197 | `LevelRenderer` |
| `AsyncTextureMixin.java` | 17 | `SimplePreparableReloadListener` |
| `TextureManagerMixin.java` | 22 | `TextureManager` |
| `LevelLoadingScreenMixin.java` | 50 | `LevelLoadingScreen` |
| `ModelPartMixin.java` | 103 | `ModelPart` |
| `BufferBuilderMixin.java` (sorting) | 47, 76 | `BufferBuilder` |
| `DirectionMixin.java` | 32 | `Direction` / `FaceBakery` |
| `MatrixStackMixin.java` | 26, 49 | `PoseStack` |
| `SpriteContentsInterpolationMixin.java` | 42 | `SpriteContents$Interpolation` |
| `MipmapHelperMixin.java` | 41 | `MipmapGenerator` |
| `BiomeMixin.java` | 71 | `Biome` |

### @Inject/@Redirect targets with Yarn names (11 errors)

| File | Line | Type | Yarn target | Target class |
|------|------|------|-------------|-------------|
| `MinecraftClientMixin.java` | 89 | @Inject | `reloadResources` | `Minecraft` |
| `WorldRendererMixin.java` (core) | 176 | @Inject | `reload` | `LevelRenderer` |
| `WorldRendererMixin.java` (core) | 52 | @Redirect | `reload` | `LevelRenderer` |
| `ModelPartMixin.java` | 85 | @Inject | `render` | `ModelPart` |
| `WorldRendererMixin.java` (outlines) | 29 | @Inject | `drawBox` | `LevelRenderer` |
| `BlockModelRendererMixin.java` | 37 | @Inject | `render` | `ModelBlockRenderer` |
| `WorldRendererMixin.java` (clouds) | 43, 50 | @Inject | `reload` | `LevelRenderer` |
| `WorldRendererMixin.java` (sky) | 33 | @Inject | `renderSky` | `LevelRenderer` |
| `DrawContextMixin.java` | 13, 22 | @Inject | `drawSprite` | `GuiGraphics` (?) |
| `SpriteBillboardParticleMixin.java` | 29 | @Inject | `setSprite` | `TextureSheetParticle` |

### @Accessor fields with Yarn names (5 errors)

| File | Yarn field | Target class |
|------|-----------|-------------|
| `NativeImageAccessor.java` | `pointer` | `NativeImage` |
| `SpriteContentsAccessor.java` | `mipmapLevelsImages` | `SpriteContents` |
| `SpriteContentsAnimationAccessor.java` | `frameCount` | `SpriteContents$AnimatedTexture` |
| `SpriteContentsAnimatorImplAccessor.java` | `animation` | `SpriteContents$Ticker` |
| `SpriteContentsAnimatorImplAccessor.java` | `currentTime` | `SpriteContents$Ticker` |

### Mixin target class not found (2 errors)

| File | Problem |
|------|---------|
| `BufferBuilderMixin.java` (consumer) | `@Mixin` target not resolving — `BufferBuilder` lives in `com.mojang.blaze3d.vertex` now |
| `OverlayVertexConsumerMixin.java` | Target `SheetedDecalTextureGenerator` — wrong name or package |

---

## Error totals

| Category | Count | How hard |
|----------|-------|----------|
| Wrong class/inner class name | ~35 | Easy — just look up and rename |
| Missing/wrong import | ~17 | Easy — add the right import |
| @Overwrite method names | ~16 | Medium — need Mojang method name lookups |
| @Inject/@Redirect targets | ~11 | Medium — same deal |
| @Accessor field names | 5 | Medium — need SRG/Mojang field lookups |
| Mixin target not found | 2 | Medium — fix target class reference |
| **Total** | **~100** | |

---

## Game plan for the remaining fixes

**Step 1 — knock out the easy stuff (~52 errors)**

Most of these are the same mistake repeated. Fixing `PoseStack.Entry` -> `PoseStack.Pose` alone kills 15 errors. Adding a handful of missing imports gets another 15. The rest are one-off class name lookups.

Quick wins:
1. `PoseStack.Entry` -> `PoseStack.Pose` globally (15 errors gone)
2. Add missing imports: `Camera`, `BlockDestructionProgress`, `Frustum`, `BufferBuilder`, `BlockState` (12 gone)
3. `BiomeEffects` -> `BiomeSpecialEffects` (2 gone)
4. `Biome.Weather` -> `Biome.ClimateSettings` (1 gone)
5. `CubicSampler.RgbFetcher` -> `CubicSampler.ColorFetcher` (2 gone)
6. Kill the bad `MutableBlockPos` imports from the mixin package (2 gone)
7. `Weighted` -> `WeightedEntry` + fix package (3 gone)
8. `RunArgs` -> `GameConfig`, `ChunkData`/`LightData` inner classes (3 gone)

**Step 2 — mixin method/field lookups (~34 errors)**

Use [Linkie](https://linkie.shedaniel.me/) or the Mojang mapping files to find every @Overwrite, @Inject, @Redirect, and @Accessor target's real name. Tedious but straightforward.

**Step 3 — fix the 2 broken mixin targets**

Sort out the `BufferBuilder` import path and figure out what `SheetedDecalTextureGenerator` is actually called.

**Step 4 — warnings + runtime test**

Deal with the 100 warnings (mostly unused imports and unchecked casts), then actually launch Minecraft and see if the mixins apply.

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

---

## Things that could bite me later

1. **The sed script was a blunt instrument.** It renamed Sodium's own classes along with Minecraft's. I caught ~35 files, but there could be subtler damage hiding in the code that compiles fine but breaks at runtime.

2. **Mixin targets assume Fabric's Yarn mappings.** Even once everything compiles, the mixins need to hook into the right methods at runtime. ForgeGradle with `mappings("official", "1.20.1")` means everything has to be in Mojang name space.

3. **Access Transformer might be missing entries.** The `accesstransformer.cfg` was written from the original `sodium.accesswidener`, but I haven't verified every single entry maps correctly.

4. **Forge-specific hooks aren't wired up yet.** Still need to deal with:
   - Forge event bus registration
   - `IForgeBlock`/`IForgeFluid` extensions
   - `RenderLevelStageEvent` vs Fabric's `WorldRenderEvents`
   - Forge's model loading differences

5. **`FlawlessFrames.java`** has a Fabric-only integration (FREX/Canvas). Probably needs to be gutted or replaced.

6. **Zero runtime testing so far.** Only `./gradlew compileJava` has been run. No idea if it actually works in-game yet.
