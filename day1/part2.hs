import System.Environment

unfoldr :: (y -> Maybe (x, y)) -> (y -> [x])
unfoldr f b = case f b of
    Just (x, y') -> x : unfoldr f y'
    Nothing      -> []


main :: IO ()
main = do
    args <- getArgs
    input <- readFile (args !! 0)
    let set = (map read (lines input)) :: [Int]
    print
        (foldl (\x y -> x + sum
            (drop 1 (unfoldr
                (\z -> if z <= 0
                    then Nothing
                    else Just (z, (div z 3) - 2)
                ) y
            ))) 0 set
        )
