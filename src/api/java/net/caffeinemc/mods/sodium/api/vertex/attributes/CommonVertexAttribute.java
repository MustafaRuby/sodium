package net.caffeinemc.mods.sodium.api.vertex.attributes;

import com.mojang.blaze3d.vertex.VertexFormatElement;
import com.mojang.blaze3d.vertex.DefaultVertexFormat;

public enum CommonVertexAttribute {
    POSITION(DefaultVertexFormat.POSITION_ELEMENT),
    COLOR(DefaultVertexFormat.COLOR_ELEMENT),
    TEXTURE(DefaultVertexFormat.TEXTURE_ELEMENT),
    OVERLAY(DefaultVertexFormat.OVERLAY_ELEMENT),
    LIGHT(DefaultVertexFormat.LIGHT_ELEMENT),
    NORMAL(DefaultVertexFormat.NORMAL_ELEMENT);

    private final VertexFormatElement element;

    public static final int COUNT = CommonVertexAttribute.values().length;

    CommonVertexAttribute(VertexFormatElement element) {
        this.element = element;
    }

    public static CommonVertexAttribute getCommonType(VertexFormatElement element) {
        for (var type : CommonVertexAttribute.values()) {
            if (type.element == element) {
                return type;
            }
        }

        return null;
    }

    public int getByteLength() {
        return this.element.getByteLength();
    }
}
