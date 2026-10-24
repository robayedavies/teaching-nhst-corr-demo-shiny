# Sampling-variability comparison app
#
# Compares ONE observed (simulated) dataset's r and t with two representations of
# sampling variability: six more datasets from the same population, and two piles of
# 100 simulated studies (H0 true / HA true). All logic lives in
# ../nhst-sampling-variability.R; this file is only the interface.
#
# Run from the project root with:
#   shiny::runApp("nhst-sampling-variability-app")
#
# Requires: shiny, bslib, ggplot2, ggdist, MASS (see the walkthrough,
# nhst-sampling-variability-walkthrough.qmd).

library(shiny)
library(bslib)
library(ggplot2)

# Helper scripts: looked for next to this file first (for a deployed bundle), then in the
# project root (the folder above this one).
src <- function(f) source(if (file.exists(f)) f else file.path("..", f))
src("psych-battery-dgp.R")
src("nhst-fisher-neyman-pearson-demo.R")
src("nhst-sampling-variability.R")

random_seed <- function() sample.int(10000, 1)

# Safari workaround. In shinylive (webR), renderPlot() fails in Safari with "RangeError:
# Maximum call stack size exceeded" and the app stalls (posit-dev/r-shinylive issue #204,
# open as of 2026-10-24). Drawing the plot to a PNG ourselves and returning it with
# renderImage() avoids that path and works in every browser tested. It also works in a normal
# Shiny session. `id` must be the output's id (its size is read from session$clientData).
render_plot_image <- function(id, session, make_plot) {
  renderImage({
    w  <- session$clientData[[paste0("output_", id, "_width")]]
    h  <- session$clientData[[paste0("output_", id, "_height")]]
    pr <- session$clientData$pixelratio
    req(w, h, w > 20, h > 20)
    if (is.null(pr)) pr <- 1
    f <- tempfile(fileext = ".png")
    grDevices::png(f, width = w * pr, height = h * pr, res = 96 * pr)
    tryCatch(print(make_plot()), finally = grDevices::dev.off())
    list(src = f, contentType = "image/png", width = w, height = h)
  }, deleteFile = TRUE)
}


# ---- User interface ------------------------------------------------------------------

ui <- page_fillable(
  title = "Sampling variability: our dataset versus H0 and HA",
  theme = bs_theme(version = 5),
  padding = 12,
  gap = 12,

  # Control bar (kept short so the three plot cards get most of a 720-px-high screen)
  card(
    fill = FALSE,
    class = "py-1",
    layout_columns(
      col_widths = c(2, 4, 2, 2, 2),
      # dropdownParent = "body": otherwise the menu is clipped by the card and the
      # control bar scrolls instead of the list
      selectizeInput("n", "Participants per study (N)", choices = sv_n_choices, selected = 30,
                     width = "100%",
                     options = list(dropdownParent = "body")),
      sliderInput("r", "Population correlation (r)", min = sv_r_limits[1], max = sv_r_limits[2],
                  value = 0.3, step = 0.05, width = "100%"),
      numericInput("seed", "Seed", value = random_seed(), min = 1, max = 10000, step = 1,
                   width = "100%"),
      div(
        class = "d-flex flex-column justify-content-center h-100 gap-1",
        actionButton("new_samples", "Draw new samples", class = "btn-primary btn-sm w-100"),
        actionButton("new_piles", "Redraw the piles", class = "btn-outline-secondary btn-sm w-100")
      ),
      div(
        class = "d-flex flex-column justify-content-center h-100",
        checkboxInput("zoom", "Zoom to piles", value = FALSE, width = "100%"),
        span(class = "small text-muted", "alpha = .05 (fixed)")
      )
    )
  ),

  # Three columns
  layout_columns(
    col_widths = c(4, 4, 4),
    card(
      card_header(class = "py-1", "1. Our observed dataset"),
      imageOutput("focal", fill = TRUE),
      card_footer(class = "small py-1", uiOutput("focal_note"))
    ),
    card(
      card_header(class = "py-1", "2. Six more datasets, same population"),
      imageOutput("grid", fill = TRUE),
      card_footer(class = "small py-1", uiOutput("grid_note"))
    ),
    card(
      card_header(class = "py-1", "3. Where does our r fall? 100 studies per world"),
      imageOutput("pile_h0", fill = TRUE),
      imageOutput("pile_ha", fill = TRUE),
      card_footer(class = "small py-1", uiOutput("pile_note"))
    )
  )
)


# ---- Server --------------------------------------------------------------------------

server <- function(input, output, session) {

  rv <- reactiveValues(pile_seed = random_seed())

  # "Draw new samples" writes a fresh seed into the seed box; the focal dataset and the
  # six-grid then redraw from it, and anyone can reproduce the screen by typing it in.
  observeEvent(input$new_samples, updateNumericInput(session, "seed", value = random_seed()))
  observeEvent(input$new_piles, rv$pile_seed <- random_seed())

  n_val <- reactive(as.integer(input$n))

  seed_val <- reactive({
    s <- input$seed
    validate(need(!is.null(s) && !is.na(s) && s >= 1 && s <= 10000 && s == round(s),
                  "Seed must be a whole number from 1 to 10000."))
    as.integer(s)
  })

  # cache = "session" (not the default app cache) so the same app.R also runs as a static
  # shinylive page, where no app-level cache is set up
  fg <- reactive(simulate_focal_and_grid(n_val(), input$r, seed_val())) |>
    bindCache(n_val(), input$r, seed_val(), cache = "session")

  piles <- reactive(simulate_piles(n_val(), input$r, rv$pile_seed)) |>
    bindCache(n_val(), input$r, rv$pile_seed, cache = "session")

  # The colour key lives in the card footer, which frees the vertical space a legend takes
  pile_for_app <- function(world) {
    plot_pile(piles(), world, fg()$focal_stats$r, zoom = input$zoom) +
      theme(legend.position = "none",
            plot.title = element_text(face = "bold", size = 13),
            plot.subtitle = element_text(size = 11))
  }

  output$focal   <- render_plot_image("focal", session, function() plot_focal_scatter(fg()))
  output$grid    <- render_plot_image("grid", session, function() plot_comparison_grid(fg()))
  output$pile_h0 <- render_plot_image("pile_h0", session, function() pile_for_app("h0"))
  output$pile_ha <- render_plot_image("pile_ha", session, function() pile_for_app("ha"))

  output$focal_note <- renderUI({
    helpText(sprintf(paste("HA world: population r = %.2f (%s), N = %d.",
                           "t = r*sqrt(N-2)/sqrt(1-r^2) on N-2 df."),
                     input$r, r_size_label(input$r), n_val()))
  })

  output$grid_note <- renderUI({
    helpText("Same population r, same N, independent random samples: each study gives a different r and t.")
  })

  output$pile_note <- renderUI({
    base <- tagList(
      span(style = "color:#0072B2; font-weight:bold", "Blue"), ": not significant; ",
      span(style = "color:#E69F00; font-weight:bold", "orange"), ": significant. ",
      "Dashed: critical r. ",
      span(style = "color:#B23A48; font-weight:bold", "Red"), ": our observed r.")
    if (abs(input$r) < 1e-9) {
      helpText(base, "At r = 0, H0 and HA describe the same population, so both piles are draws from it.")
    } else {
      helpText(base)
    }
  })
}

shinyApp(ui, server)
