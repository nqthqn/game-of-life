module GameOfLife exposing
    ( Cell(..)
    , Events
    , GameOfLife
    , Zoom(..)
    , begin
    , beginWithPattern
    , isFinished
    , step
    , toggleCell
    , view
    )

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseUp)
import Matrix exposing (Coordinate, Matrix)
import Pattern exposing (Pattern)



-- TYPES


type Cell
    = Alive
    | Dead


type alias Cells =
    Matrix Cell


type GameOfLife
    = GameOfLife Cells



-- CREATE


begin : GameOfLife
begin =
    Matrix.create { width = 18, height = 18 } Dead
        |> GameOfLife


beginWithPattern : Pattern -> GameOfLife
beginWithPattern pattern =
    let
        size =
            max (Pattern.width pattern) (Pattern.height pattern)
                |> toFloat
                |> (*) 1.2
                |> max 18
                |> Basics.round

        center =
            { x = size // 2
            , y = size // 2
            }

        centeredPattern =
            Pattern.centerAt center pattern

        deadCells =
            Matrix.create { width = size, height = size } Dead
    in
    GameOfLife <|
        List.foldl
            (Matrix.set Alive)
            deadCells
            (Pattern.toCoordinates centeredPattern)



-- OPERATIONS


step : GameOfLife -> GameOfLife
step (GameOfLife cells) =
    Matrix.coordinateMap (stepCell cells) cells
        |> GameOfLife


stepCell : Cells -> Coordinate -> Cell -> Cell
stepCell cells coordinate cell =
    case ( cell, countLiveNeighbours cells coordinate ) of
        ( Alive, 2 ) ->
            Alive

        ( Alive, 3 ) ->
            Alive

        ( Dead, 3 ) ->
            Alive

        _ ->
            Dead


countLiveNeighbours : Cells -> Coordinate -> Int
countLiveNeighbours cells coordinate =
    Matrix.neighbours cells coordinate
        |> List.filter ((==) Alive)
        |> List.length


toggleCell : Coordinate -> GameOfLife -> GameOfLife
toggleCell coordinate (GameOfLife cells) =
    let
        toggle cell =
            case cell of
                Alive ->
                    Dead

                Dead ->
                    Alive
    in
    Matrix.update toggle coordinate cells
        |> GameOfLife


isFinished : GameOfLife -> Bool
isFinished (GameOfLife cells) =
    Matrix.all ((==) Dead) cells



-- VIEW


type alias Percentage =
    Float


type alias Events msg =
    { onMouseOver : Coordinate -> msg
    , onMouseDown : Coordinate -> msg
    , onMouseUp : msg
    }


type Zoom
    = Far
    | Normal
    | Close


view : GameOfLife -> Zoom -> Events msg -> Html msg
view game zoom events =
    div
        [ class "square-container" ]
        [ viewCells game zoom events ]


viewCells : GameOfLife -> Zoom -> Events msg -> Html msg
viewCells (GameOfLife cells) zoom events =
    div
        ([ class "cells-container" ] ++ zoomStyles zoom)
        (cells
            |> Matrix.coordinateMap (viewCell (cellSize cells) events)
            |> Matrix.toList
        )


zoomStyles : Zoom -> List (Attribute msg)
zoomStyles zoom =
    let
        percentage =
            case zoom of
                Far ->
                    percentageStyle 100

                Normal ->
                    percentageStyle 150

                Close ->
                    percentageStyle 200
    in
    [ style "width" percentage
    , style "height" percentage
    ]


viewCell : Percentage -> Events msg -> Coordinate -> Cell -> Html msg
viewCell relativeSize events coordinate cell =
    div
        [ class "center-content"
        , style "width" (percentageStyle relativeSize)
        , style "height" (percentageStyle relativeSize)
        , onMouseDown (events.onMouseDown coordinate)
        , onMouseUp events.onMouseUp
        , onMouseEnter (events.onMouseOver coordinate)
        ]
        [ viewCellContent cell coordinate ]


viewCellContent : Cell -> Coordinate -> Html msg
viewCellContent cell coordinate =
    let
        size =
            cellContentSize cell
    in
    div
        [ class "cell-content"
        , cellBackgroundColor cell coordinate
        , style "width" (percentageStyle size)
        , style "height" (percentageStyle size)
        ]
        []


percentageStyle : Percentage -> String
percentageStyle value =
    String.fromFloat value ++ "%"


cellSize : Cells -> Percentage
cellSize cells =
    100.0 / (Matrix.width cells |> toFloat)


cellContentSize : Cell -> Percentage
cellContentSize cell =
    case cell of
        Alive ->
            70

        Dead ->
            40


cellBackgroundColor : Cell -> Coordinate -> Attribute msg
cellBackgroundColor cell { x, y } =
    case cell of
        Dead ->
            backgroundColor 244 245 247 1.0

        Alive ->
            case ( modBy 2 x == 0, modBy 2 y == 0 ) of
                ( True, True ) ->
                    backgroundColor 255 171 0 0.8

                ( True, False ) ->
                    backgroundColor 54 179 126 0.8

                ( False, True ) ->
                    backgroundColor 0 184 217 0.8

                ( False, False ) ->
                    backgroundColor 101 84 192 0.8


backgroundColor : Int -> Int -> Int -> Float -> Attribute msg
backgroundColor red green blue alpha =
    let
        colorString =
            "rgba("
                ++ String.fromInt red
                ++ ", "
                ++ String.fromInt green
                ++ ", "
                ++ String.fromInt blue
                ++ ", "
                ++ String.fromFloat alpha
                ++ ")"
    in
    style "background-color" colorString
