module Main where

import qualified Data.HashMap.Strict as HashMap
import Data.HashMap.Strict (HashMap)
import Data.Monoid
import Data.Maybe
import Options.Applicative
import System.Process
import Text.Printf

getBranches :: String
getBranches = "git branch -v | grep -v '^ [*]' |sed -e 's/^[*]//;s/^ *//;s/  */ /' | cut -f 1,2 -d ' ' | grep -v '[.]bck[.][0-9]*'"

readShell :: String -> IO String
readShell = flip readCreateProcess "" . shell

toBranchTuples :: [[String]] -> [(String, String)]
toBranchTuples = mapMaybe toTuple
  where 
    toTuple [branch, hash] = Just (hash, branch)
    toTuple _ = Nothing

branchesMapping :: [[String]] -> HashMap String [String]
branchesMapping = HashMap.fromListWith (++) . map (\(f, s) -> (f, [s])) . toBranchTuples

addBranchMove :: HashMap String [String] -> String -> Maybe [String]
addBranchMove hm hash = case HashMap.lookup hash hm of
  Just branchNames -> Just $ map 
    (\branchName -> printf "exec git backup '%s' && git branch -f '%s' HEAD" branchName branchName)
    branchNames
  Nothing -> Nothing

addScalaTest :: Options -> [String]
addScalaTest options = case commands of 
  [] -> []
  x -> ["exec sbt " ++ unwords x]
  where 
  commands =
    [ printf "'%s/%s'" project test
    | test <- scalaTestCommands options
    , project <- scalaTestProjects options
    ]

whenInterestingCommit 
  :: Options 
  -> HashMap String a
  -> (String -> [String])
  -> String 
  -> Maybe [String]
whenInterestingCommit options hm func hash = 
  if HashMap.member hash hm || not (insertAtBranches options) 
    then Just (func hash)
    else Nothing

enrichLines :: [String -> Maybe [String]] -> [[String]] -> [[String]]
enrichLines funcs = mconcat . map (\line -> line : pick line)
  where
    pick :: [String] -> [[String]]
    pick ("pick" : hash : _) = map (:[]) $ mconcat $ mapMaybe (\f -> f hash) funcs
    pick _ = []

data Options = Options
  { moveBranches :: Bool
  , commands :: [String]
  , scalaTestProjects :: [String]
  , scalaTestCommands :: [String]
  , insertAtBranches :: Bool
  }

optionsParser :: Parser Options
optionsParser = Options
  <$> (not <$> switch 
    ( long "dont-touch-branches" 
    <> help "Whether to move branches or not."
    ))
  <*> many (strOption 
    ( long "command"
    <> short 'c'
    <> metavar "COMMAND"
    <> help "Execute this command after each commit/branch point."
    ))
  <*> many (strOption
    ( long "scala-project"
    <> short 'p'
    <> metavar "Project"
    <> help "Run test in following project after each commig/branch point."
    ))
  <*> many (strOption
    ( long "scala-test-type"
    <> short 't'
    <> metavar "TEST_COMMAND"
    <> help "Which test command to run in sbt. For example 'compile', 'test', 'test:compile', ..."
    ))
  <*> (not <$> switch 
    (long "commands-after-each-commit" 
    <> short 'a' 
    <> help "Insert commands after each commit, not just branches."
    ))

parseOptions :: IO Options
parseOptions = execParser
  (info (optionsParser <**> helper)
    ( fullDesc
    <> progDesc "git-todo: enrich git rebase todo list with branch moves, tests and arbitrary commands."
    )
  )

main :: IO ()
main = do
  options <- parseOptions
  branches <- branchesMapping . map words . lines <$> readShell getBranches
  input <- map words . lines <$> getContents
  putStrLn $ unlines $ map unwords $ enrichLines 
    [ whenInterestingCommit options branches (const (map ("exec " ++) $ commands options))
    , whenInterestingCommit options branches (const (addScalaTest options))
    , if moveBranches options then addBranchMove branches else const Nothing
    ]
    input
