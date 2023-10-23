--------------------------------------------------------------------------------

module Utils
  ( loadPaginate,
    loadPostData,
    loadTags,
    alphabetical,
    reverseAlphabetical,
  )
where

--------------------------------------------------------------------------------

import Control.Monad (forM)
import Data.Binary (Binary)
import Data.List (sortOn)
import Data.Map (elems, keys)
import Hakyll
import Hakyll.Web.NumberedPostList
import Type.Reflection (Typeable)

--------------------------------------------------------------------------------

-- | Given a Paginate object, return a list of pages that it creates
loadPaginate ::
  (Binary a, Typeable a) =>
  Paginate ->
  Compiler [Item a]
loadPaginate pag =
  forM (keys $ paginateMap pag) (load . paginateMakeId pag)

-- | Given a PostData object (from BetterPages), return a list of Items
loadPostData ::
  (Binary a, Typeable a) =>
  PostData ->
  Compiler [Item a]
loadPostData postdata =
  forM (elems $ postMap postdata) load

-- | Given a Tags object, return a list of Items corresponding to the generated
--   pages
loadTags ::
  (Binary a, Typeable a) =>
  Tags ->
  Compiler [Item a]
loadTags tags =
  forM (tagsMap tags) $ \(tag, _) -> (load . tagsMakeId tags) tag

-- | Given a list of items, sort them in alphabetical order according to their
--   identifier
alphabetical :: [Item a] -> [Item a]
alphabetical =
  sortOn $ show . itemIdentifier

-- | Given a list of items, sort them in reverse alphabetical order
reverseAlphabetical :: [Item a] -> [Item a]
reverseAlphabetical = reverse . alphabetical
