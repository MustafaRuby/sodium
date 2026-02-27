package me.jellysquid.mods.sodium.client.gui.options;

import net.minecraft.network.chat.Component;
import net.minecraft.ChatFormatting;

public enum OptionImpact implements TextProvider {
    LOW(ChatFormatting.GREEN, "sodium.option_impact.low"),
    MEDIUM(ChatFormatting.YELLOW, "sodium.option_impact.medium"),
    HIGH(ChatFormatting.GOLD, "sodium.option_impact.high"),
    VARIES(ChatFormatting.WHITE, "sodium.option_impact.varies");

    private final Component text;

    OptionImpact(ChatFormatting color, String text) {
        this.text = Component.translatable(text).formatted(color);
    }

    @Override
    public Component getLocalizedName() {
        return this.text;
    }
}
