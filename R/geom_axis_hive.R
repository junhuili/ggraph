#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto
#' @importFrom dplyr %>% group_by_ mutate_ slice ungroup
#' @export
StatAxisHive <- ggproto('StatAxisHive', StatFilter,
    setup_data = function(data, params) {
        data <- data %>% group_by_(~angle, ~section, ~PANEL) %>%
            mutate_(x = ~min(r)*cos(angle[1]) * 1.1,
                    y = ~min(r)*sin(angle[1]) * 1.1,
                    xend = ~max(r)*cos(angle[1]) * 1.1,
                    yend = ~max(r)*sin(angle[1]) * 1.1,
                    max_r = ~max(r),
                    min_r = ~min(r)
            ) %>%
            slice(1) %>%
            ungroup()
        as.data.frame(data)
    },
    required_aes = c('r', 'angle', 'centerSize', 'axis', 'section'),
    extra_params = c('na.rm', 'n', 'curvature')
)
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto GeomSegment
#' @importFrom grid textGrob nullGrob
#' @importFrom dplyr %>% group_by_ summarise_
#' @export
GeomAxisHive <- ggproto('GeomAxisHive', GeomSegment,
    draw_panel = function(data, panel_scales, coord, label = TRUE, axis = TRUE, lab_colour = 'black', lab_size = 3.88, lab_family = '', lab_fontface = 1, lab_lineheight = 1.2) {
        data$x <- data$x / 1.1
        data$y <- data$y / 1.1
        data$xend <- data$xend / 1.1
        data$yend <- data$yend / 1.1
        data <- coord$transform(data, panel_scales)
        labelData <- data %>% group_by_(~axis) %>%
            summarise_(x = ~max(max_r) * cos(mean(angle)),
                       y = ~max(max_r) * sin(mean(angle)),
                       label = ~axis[1],
                       angle = ~mean(angle)/(2*pi) * 360 - 90
            )
        labelData <- as.data.frame(labelData)
        labDist <- sqrt(labelData$x^2 + labelData$y^2)
        distDodge <- max(labDist) * 1.05 - max(labDist)
        labelData$x <- labelData$x * (distDodge + labDist)/labDist
        labelData$y <- labelData$y * (distDodge + labDist)/labDist
        labelData$angle <- labelData$angle + ifelse(labelData$angle < 0, 360, 0)
        labelData$angle <- labelData$angle - ifelse(labelData$angle > 360, 360, 0)
        upsideLabel <- labelData$angle > 90 & labelData$angle < 270
        labelData$angle[upsideLabel] <- labelData$angle[upsideLabel] + 180
        labelData <- coord$transform(labelData, panel_scales)
        labelGrob <- if (label) {
            textGrob(labelData$label, labelData$x, labelData$y,
                     default.units = 'native', rot = labelData$angle,
                     gp = gpar(col = lab_colour,
                               fontsize = lab_size * .pt,
                               fontfamily = lab_family,
                               fontface = lab_fontface,
                               lineheight = lab_lineheight))
        } else {
            nullGrob()
        }
        axisGrob <- if (axis) {
            segmentsGrob(data$x, data$y, data$xend, data$yend,
                         default.units = 'native',
                         gp = gpar(col = alpha(data$colour, data$alpha),
                                   fill = alpha(data$colour, data$alpha),
                                   lwd = data$size * .pt,
                                   lty = data$linetype,
                                   lineend = 'square')
            )
        } else {
            nullGrob()
        }
        gList(axisGrob, labelGrob)
    },
    default_aes = aes(colour = 'black', size = 0.5, linetype = 1, alpha = NA)
)

#' @export
geom_axis_hive <- function(mapping = NULL, data = NULL,
                           position = "identity", label = TRUE, axis = TRUE, show.legend = NA, ...) {
    mapping <- aesIntersect(mapping, aes_(r=~r, angle=~angle, centerSize=~centerSize, axis=~axis, section=~section))
    layer(data = data, mapping = mapping, stat = StatAxisHive,
          geom = GeomAxisHive, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(na.rm = FALSE, label = label, axis = axis, ...)
    )
}
