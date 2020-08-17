--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Maybe  (fromMaybe)
import           Data.Monoid (mappend)
import           Hakyll
import qualified GHC.IO.Encoding as E
import qualified Data.Text as T

import           Utils
import           TagFormat


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

    match "css/*" $ do
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

    match "posts/*" $ do
      route $ metadataRoute titleRoute
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html"    postCtxWithTags
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    tagsRules tags $ \tag pattern -> do
      route $ tagRoute tag
      let title = "Posts tagged with \"" ++ tag ++ "\""
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let tagCtx =
              constField "title" title                         `mappend`
              listField "posts" postCtxWithTags (return posts) `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html"     tagCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let archiveCtx =
              listField "posts" postCtx (return posts) `mappend`
              constField "title" "Archives"            `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    create ["tags.html"] $ do
      route idRoute
      compile $ do
        let allTagsCtx = 
              field "tags" (return (betterRenderTags tags)) `mappend`
              constField "title" "Tags"      `mappend`
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
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

tagRoute :: String -> Routes
tagRoute =
  constRoute . T.unpack . (`T.append` ".html") . toSlug . T.pack

betterRenderTags :: Tags -> Compiler String
betterRenderTags =
  renderTags formatTagItem formatJoinTags

titleRoute :: Metadata -> Routes
titleRoute = fieldRoute "Untitled" "title"

fieldRoute :: String -> String -> Metadata -> Routes
fieldRoute placeholder fieldName =
  constRoute . (fileNameFromMeta placeholder fieldName)

fileNameFromMeta :: String -> String -> Metadata -> FilePath
fileNameFromMeta placeholder fieldName =
  T.unpack . (`T.append` ".html") . toSlug . T.pack 
           . (getFieldFromMeta placeholder fieldName)

getFieldFromMeta :: String -> String -> Metadata -> String
getFieldFromMeta placeholder fieldName =
  fromMaybe placeholder . lookupString fieldName
