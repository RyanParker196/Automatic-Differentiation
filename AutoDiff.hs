{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}
module AutoDiff where
--imports
import Data.Set (Set)
import qualified Data.Set as Set

import Data.Map (Map)
import qualified Data.Map as Map

-- v ∈ value ≜ ℝ
type Value = Double

-- d ∈ derivative ≜ ℝ
type Derivative = Double

-- v̂ ∈ value^ ⩴ ⟨v,d⟩
data ValueHat = DualNum Value Derivative
    deriving (Eq,Ord,Read,Show)

-- γ̂ ∈ env^ ≜ var ⇀ value^
type EnvHat = Map String ValueHat
type Env = Map String Value

--NEW TYPES FOR REVERSE MODE
data ValueR = DualNumber Value (Derivative -> Derivative)

instance Show ValueR where
    show (DualNumber v dd) = show (FDualNumber v (dd 1))

data FValue = FDualNumber Value Derivative
  deriving (Eq,Ord,Show)

finalValue :: ValueR -> FValue
finalValue (DualNumber v f) = FDualNumber v (f 1)

finalValueMaybe :: Maybe ValueR -> Maybe FValue
finalValueMaybe Nothing = Nothing
finalValueMaybe (Just v) = Just (finalValue v)

type EnvR = Map String ValueR

-- x ∈ var
-- r ∈ ℝ
-- e ⩴ x | r | e + e | e × e | sin(e) | cos(e)
data Expr = RealE Double
          | PlusE Expr Expr
          | TimesE Expr Expr
          | SinE Expr
          | CosE Expr
          | VarE String
  deriving (Eq,Ord,Read,Show)

interp :: EnvHat -> Expr -> Value
interp env e = case e of
    RealE r -> r
    VarE s -> case Map.lookup s env of
        Just (DualNum v d) -> v
        Nothing -> error "Free Var"
    SinE e -> case interp env e of
        v -> sin v
    CosE e -> case interp env e of
        v -> cos v
    PlusE e1 e2 -> case (interp env e1, interp env e2) of
        (v1, v2) -> (v1 + v2)
    TimesE e1 e2 -> case (interp env e1, interp env e2) of
        (v1, v2) -> (v1 * v2)

derive :: EnvHat -> Expr -> Derivative
derive env e = case e of
    RealE r -> 0
    VarE s -> case Map.lookup s env of
        Just (DualNum v d) -> v
        Nothing -> error "Free Var"
    SinE e -> case interp env e of
        v -> (cos v) * (derive env e)
    CosE e -> case interp env e of
        v -> (-sin v) * (derive env e)
    PlusE e1 e2 -> case ((derive env e1), (derive env e2)) of
        (v1, v2) -> (v1 + v2)
    TimesE e1 e2 -> case ((derive env e1), (derive env e2))of
        (v1, v2) -> (v1 * v2)

forward :: EnvHat -> Expr -> Maybe ValueHat
forward env e = case e of
    RealE r -> Just (DualNum r 0)
    VarE s -> case Map.lookup s env of
        Just vh -> Just vh
        Nothing -> Nothing
    SinE e -> case forward env e of
        Just (DualNum v d) -> Just (DualNum (sin v) (cos v))
        Nothing -> Nothing
    CosE e -> case (interp env e, derive env e )of
        (v,d) -> Just (DualNum v d)
    PlusE e1 e2 -> case (forward env e1, forward env e2) of
        (Just (DualNum v1 d1),Just (DualNum v2 d2))
            -> Just (DualNum (v1 + v2) (d1 + d2))
        (_,_) -> Nothing
    TimesE e1 e2 -> case (forward env e1,forward env e2) of
        (Just (DualNum v1 d1),Just (DualNum v2 d2))
            -> Just (DualNum (v1 * v2) ((d1 * v2) + (d2 * v1)))
        (_,_) -> Nothing

reversed :: EnvR -> Expr -> Maybe ValueR
reversed env e = case e of
    RealE r -> Just (DualNumber r (\k'->0))
    VarE s -> case Map.lookup s env of
        Just vr -> Just vr
        Nothing -> Nothing
    SinE e -> case reversed env e of
        Just (DualNumber v k)
            -> Just (DualNumber (sin v) (\k'-> (cos v) * (k v)))
        Nothing -> Nothing
    CosE e -> case reversed env e of
        Just (DualNumber v k)
            -> Just (DualNumber (cos v) (\k'-> (-sin v) * (k v)))
        Nothing -> Nothing
    PlusE e1 e2 -> case (reversed env e1, reversed env e2) of
        (Just (DualNumber v1 k1),Just (DualNumber v2 k2))
            -> Just (DualNumber (v1 + v2) (\k'-> (k1 k') + (k2 k')))
        (_,_) -> Nothing
    TimesE e1 e2 -> case (reversed env e1,reversed env e2) of
        (Just (DualNumber v1 k1),Just (DualNumber v2 k2))
            -> Just (DualNumber (v1 * v2) (\k' -> ((k1 v2) * k') + ((k2 v1) * k')))
        (_,_) -> Nothing

