module View.Project exposing (viewInfo, viewActions)

import Html exposing (Html, div, a, table, tbody, th, tr, td, text, button, span)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Data.Project exposing (Investigator, Publication, Sample)
import Route


viewInfo
  : { a
    | project_id : Int
    , project_name : String
    , project_code : String
    , project_type : String
    , url : String
    , investigators : List Investigator
    , publications : List Publication
    , sample_count : Int
    }
  -> Html msg
viewInfo { project_id, project_name, project_code, project_type, url, investigators, publications, sample_count } =
    let
        numSamplesText =
            if sample_count == 0 then
                "None"
            else
                toString sample_count
    in
    div [ class "row" ]
        [ div [ class "table-responsive" ]
            [ table [ class "table info-table" ]
                [ tbody []
                    [ tr []
                        [ th [] [ text "Name " ]
                        , td [ class "nowrap" ]
                            [ a [ Route.href (Route.Project project_id) ] [ text project_name ] ]
                        ]
                    , tr []
                        [ th [] [ text "Code " ]
                        , td [] [ text project_code ]
                        ]
                    , tr []
                        [ th [] [ text "Type " ]
                        , td [ class "nowrap" ] [ text project_type ]
                        ]
                    , tr []
                        [ th [] [ text "URL " ]
                        , td [] [ text url ]
                        ]
                    , tr []
                        [ th [] [ text "Investigators " ]
                        , td [] (viewInvestigators investigators)
                        ]
                    , tr []
                        [ th [] [ text "Publications " ]
                        , td [] [ viewPublications publications ]
                        ]
                    , tr []
                        [ th [] [ text "Samples " ]
                        , td [] [ text numSamplesText ]
                        ]
                    ]
                ]
            ]
        ]


viewActions : { a | project_id : Int } -> Bool -> msg -> Html msg
viewActions { project_id } isDeleteable deleteMsg =
        div [ class "row" ]
            [ div [ class "table-responsive" ]
                [ table [ class "table info-table" ]
                    (tr []
                        [ td []
                            [ a [ class "btn btn-link", Route.href (Route.Project project_id) ]
                                [ span [ class "glyphicon glyphicon-share-alt" ] [], text " Open"
                                ]
                            ]
                        ] ::
                    (if isDeleteable then
                        [ tr []
                            [ td []
                                [ button [ class "btn btn-link", onClick deleteMsg ]
                                    [ span [ class "glyphicon glyphicon-trash" ] [], text " Delete"
                                    ]
                                ]
                            ]
                        ]
                    else
                        []
                    )
                    )
                ]
            ]


viewInvestigators : List Investigator -> List (Html msg)
viewInvestigators investigators =
    if List.length investigators == 0 then
        [ text "None" ]
    else
        List.map investigatorLink investigators |> List.intersperse (text ", ")


investigatorLink : Investigator -> Html msg
investigatorLink investigator =
    a [ Route.href (Route.Investigator investigator.investigator_id), class "nowrap" ] [ text investigator.investigator_name ]


viewPublications : List Publication -> Html msg
viewPublications publications =
    case publications of
        [] ->
            text "None"

        _ ->
            text (List.length publications |> toString)
