#!/usr/bin/python3 -u

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont
import random
import os


def generate_background():
    random.seed()
    unicode_chars = (
        "\u2605",
        "\u2606",
        "\u2663",
        "\u2667",
        "\u2660",
        "\u2664",
        "\u2662",
        "\u2666",
        "\u263a",
        "\u263b",
        "\u26aa",
        "\u26ab",
        "\u2b53",
        "\u2b54",
        "\u2b00",
        "\u2b08",
        "\u2780",
        "\u278a",
        "\u267c",
        "\u267d",
        "\u25b2",
        "\u25b3",
    )

    unicode_max = len(unicode_chars)
    try:
        for i in range(0, 25):
            im_cropped = Image.new('RGB', (150, 150),
                                   (random.randrange(120, 255), random.randrange(120, 255), random.randrange(120, 255)))
            origwidth, origheight = im_cropped.size

            watermark = Image.new("RGBA", im_cropped.size)
            waterdraw = ImageDraw.ImageDraw(watermark, "RGBA")
            number_of_shapes = random.randrange(10, 15)
            for step in range(0, number_of_shapes):
                fillcolor = (
                    random.randrange(0, 255), random.randrange(0, 255), random.randrange(0, 255),
                    random.randrange(240, 255))
                u_char = unicode_chars[random.randrange(0, unicode_max)]
                font = ImageFont.truetype("/etc/nginx/font.ttf", random.randrange(25, 30))
                waterdraw.text((random.randrange(-10, 130), random.randrange(-10, 130)), u_char, fill=fillcolor, font=font)
            im_cropped.paste(watermark, None, watermark)
            im_cropped.save("/tmp/background-" + str(i) + '.jpg', format="JPEG")

    except Exception as e:
        print(str(e))

generate_background()