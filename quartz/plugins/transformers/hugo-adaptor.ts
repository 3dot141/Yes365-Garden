import matter from "gray-matter"
import remarkFrontmatter from "remark-frontmatter"
import { QuartzTransformerPlugin } from "../types"
import yaml from "js-yaml"
import toml from "toml"

export interface Options {
  delims: string | string[]
  language: "yaml" | "toml"
  created: string
  modified: string
}

const defaultOptions: Options = {
  delims: "---",
  language: "yaml",
  created: "created_date",
  modified: "modified_date"
}

interface HugoBean {

  date: string;
  lastmod: string;
}

export const HugoFrontMatter: QuartzTransformerPlugin<Partial<Options> | undefined> = (userOpts) => {
  const opts = { ...defaultOptions, ...userOpts }
  return {
    name: "FrontMatter",
    markdownPlugins() {
      return [
        [remarkFrontmatter, ["yaml", "toml"]],
        () => {
          return (_, file) => {

            const frontmatter = file.data.frontmatter

            if (!frontmatter) {
              return;
            }

            const created = frontmatter[opts.created]
            const modified = frontmatter[opts.modified] ? frontmatter[opts.modified] : frontmatter[opts.created]

            let hugoBean: HugoBean = {date: created, lastmod: modified}

            // fill in frontmatter
            file.data.frontmatter = {
              ...frontmatter,
              ...hugoBean
            }

          }
        },
      ]
    },
  }
}
