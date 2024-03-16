import { defineCollection } from "astro:content";
import { z } from "astro:content";

const posts = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string().optional(),
    description: z.string().optional(),
    tags: z.string().optional(),
  }),
});

export const collections = {
  posts,
};
