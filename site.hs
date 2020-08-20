--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Maybe  (fromMaybe)
import           Data.Monoid (mappend)
import           Data.List   (concat)
import           Hakyll
import qualified GHC.IO.Encoding as E

import           Hakyll.Contrib.BetterPages
import           Hakyll.Contrib.BetterArchive
import           Hakyll.Contrib.Web.CustomRoutes
import           Hakyll.Contrib.Web.TagFormat
import           Hakyll.Contrib.Web.TextUtils (firstn)

--------------------------------------------------------------------------------
main :: IO ()
main = 
  E.setLocaleEncoding E.utf8 >>
  (hakyll $ do
    match "uploads/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "uploads/favicon.ico" $ do
      route $ constRoute "favicon.ico"
      compile copyFileCompiler

    match "css/*.css" $ do
      route   idRoute
      compile compressCssCompiler

    match (fromList ["about.md", "contact.md", "privacy-policy.md"]) $ do
      route   $ setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/page.html"    defaultContext
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    tags <- buildTags "posts/*" (fromCapture "tags/*.html")
    let postCtxWithTags = tagsField "tags" tags `mappend` postCtx

    pages <- buildPagesWith "posts/*" sortChronological  

    pageRules pages $ \index _ -> do
      route $ pageIndexRoute index
      compile $ do
        let fullPostCtx = pageContext pages index `mappend` postCtxWithTags

        pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html"    fullPostCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    tagsRules tags $ \tag pattern -> do
      route $ tagRoute tag
      let title = "tag \"" ++ tag ++ "\""
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        mainTagsUrl <- urlFromIdentifier "tags.html"
        -- This is a big hack, co-opting the logic to generate a "previous page"
        -- link from pages with actual preivous/next pages. I might want to
        -- split this out into a separate template, but this works too >:)
        let tagCtx = constField "title"  title                              `mappend`
              constField "previousPageTitle" "Tags"                         `mappend`
              constField "previousPageUrl"   mainTagsUrl                    `mappend`
              constField "previousPageNum"   (show 0)                       `mappend` 
              constField "currentPageNum"   (show 1)                       `mappend` 
              listField  "posts"             postCtxWithTags (return posts) `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html"     tagCtx
          >>= loadAndApplyTemplate "templates/page.html"    tagCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    archivePages <- buildPaginateWith archivePageStrategy "posts/*" archivePageMaker

    paginateRules archivePages $ \i pattern -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let archiveCtx = archiveContext archivePages archiveTitle i `mappend` 
              listField "posts" postCtx (return posts)              `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/page.html"    archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    create ["tags.html"] $ do
      route idRoute
      compile $ do
        let allTagsCtx = 
              field "tags" (return (betterRenderTags tags)) `mappend`
              constField "title" "Tags"                     `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag-list.html" allTagsCtx
          >>= loadAndApplyTemplate "templates/page.html"     defaultContext
          >>= loadAndApplyTemplate "templates/default.html"  defaultContext
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let indexCtx =
              listField "posts" postCtx (return (firstn 5 posts)) `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler
  )

--------------------------------------------------------------------------------
-- | Add a date field to the default context
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

-- | In a compiler context, get a URL
urlFromIdentifier :: Identifier -> Compiler String
urlFromIdentifier i = getRoute i
  >>= \maybeRoute ->
    case maybeRoute of
      Just r  -> return $ toUrl r
      Nothing -> fail ("No URL for page \"" ++ show i ++ "\"")

archiveTitle :: PageNumber -> String
archiveTitle index = concat ["archives page", show index]

-- | Shorthad for applying the tag rendering found in TagFormat
betterRenderTags :: Tags -> Compiler String
betterRenderTags =
  renderTags formatTagItem formatJoinTags
