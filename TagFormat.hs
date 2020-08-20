--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

module TagFormat (formatTagItem, formatJoinTags) where

import           Data.List (concat, intercalate)

--------------------------------------------------------------------------------

formatTagItem :: String -> String -> Int -> Int -> Int -> String
formatTagItem tag url count _ _ =
  concat 
    [ "<span class=\"tag\">"
    , "<a href=\""
    , url
    , "\" class=\"tag-link\">"
    , tag
    , "</a> ("
    , show count
    , ")</span>"
    ]

formatJoinTags :: [String] -> String
formatJoinTags ss =
  concat 
    [ "<ul class=\"tag-list\"><li>"
    , intercalate "</li><li>" ss
    , "</li></ul>"
    ]
