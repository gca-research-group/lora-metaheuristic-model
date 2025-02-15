% Importación de paquetes
pkg load optim;
pkg load geometry;
pkg load control;

% Generar posiciones iniciales aleatorias
function posiciones = generar_posiciones_aleatorias(num_antenas, polygon)
    posiciones = [];
    while rows(posiciones) < num_antenas
        % Generar un punto aleatorio
        x_min = min(polygon(:, 1));
        x_max = max(polygon(:, 1));
        y_min = min(polygon(:, 2));
        y_max = max(polygon(:, 2));
        x_rand = x_min + rand * (x_max - x_min);
        y_rand = y_min + rand * (y_max - y_min);
        if inpolygon(x_rand, y_rand, polygon(:, 1), polygon(:, 2))
            posiciones = [posiciones; x_rand, y_rand];
        end
    end
end

% Calcular el costo y la cobertura
function [costo, area_cubierta_porcentaje, area_interseccion, area_total_cubierta] = calcular_costo(posiciones, radio_antena, polygon, area_objetivo)
    % Crear una grilla de puntos dentro del bounding box del polígono
    x_min = min(polygon(:, 1));
    x_max = max(polygon(:, 1));
    y_min = min(polygon(:, 2));
    y_max = max(polygon(:, 2));
    [X, Y] = meshgrid(linspace(x_min, x_max, 100), linspace(y_min, y_max, 100));
    puntos_grilla = [X(:), Y(:)];

    % Filtrar puntos dentro del polígono
    in = inpolygon(puntos_grilla(:, 1), puntos_grilla(:, 2), polygon(:, 1), polygon(:, 2));
    puntos_grilla = puntos_grilla(in, :);

    cobertura = zeros(size(puntos_grilla, 1), 1);

    for i = 1:size(posiciones, 1)
        d = sqrt((puntos_grilla(:, 1) - posiciones(i, 1)).^2 + (puntos_grilla(:, 2) - posiciones(i, 2)).^2);
        cobertura = cobertura + (d <= radio_antena);
    end

    area_cubierta = sum(cobertura > 0);
    area_interseccion = sum(cobertura > 1);
    area_total_cubierta = sum(cobertura >= 1);

    % Calcular el porcentaje del área cubierta
    area_cubierta_porcentaje = (area_cubierta / area_objetivo) * 100;

    costo = area_objetivo - area_cubierta;

    % Penalización si no se cumple el área deseada
    if area_cubierta < area_objetivo
        penalizacion = (area_objetivo - area_cubierta) * 10; % Ajustar el factor de penalización según sea necesario
        costo = costo + penalizacion;
    end
end

% Generar nuevas posiciones de antenas
function nuevas_posiciones = perturbar(posiciones, polygon)
    idx = randi(size(posiciones, 1)); % Índice aleatorio
    nuevas_posiciones = posiciones; % Copia
    nuevas_posiciones(idx, :) = generar_posiciones_aleatorias(1, polygon); % Nueva posición
end

% Función principal para ejecutar el algoritmo
function ejecutar_algoritmo(num_antenas, radio_antena)
    % Parámetros del algoritmo
    temp_inicial = 100;
    temp_final = 0.01;
    alfa = 0.9; % Factor de enfriamiento
    max_iter = 1000;

    % Cargar el archivo CSV con las coordenadas del área de la zona urbana de San Marcos
    data = csvread('prueba_sanmarcos0.csv', 1, 0);

    % Separar las columnas de latitud y longitud
    lat = data(:, 1);
    lon = data(:, 2);

    % Convertir las coordenadas de grados a metros
    R = 6378137; % Radio de la tierra en metros
    x = lon * (pi / 180) * R * cosd(mean(lat)); % Longitud en metros
    y = lat * (pi / 180) * R; % Latitud en metros

    % Calcular el área usando la fórmula de Shoelace
    area = 0;
    n = length(x);
    for i = 1:n
        j = mod(i, n) + 1;
        area = area + x(i) * y(j) - y(i) * x(j);
    end
    area = abs(area) / 2;

    % Convertir el área de metros cuadrados a kilómetros cuadrados
    area_km2 = area / 1e6;
    printf('El área de su Zona de Cobertura es: %.2f km^2\n', area_km2);

    % Definir el polígono del área urbana
    polygon = [x, y];

    % Calcular el área usando la fórmula de Gauss
    area = polygonArea(polygon); % Función del paquete geometry
    area_objetivo = area; % Mantener en metros cuadrados

    posiciones = generar_posiciones_aleatorias(num_antenas, polygon);

    % Simulated Annealing
    T = temp_inicial;
    [mejor_costo, area_cubierta, area_interseccion, area_total_cubierta] = calcular_costo(posiciones, radio_antena, polygon, area_objetivo);
    mejor_solucion = posiciones;

    % Configurar la figura para visualizar las iteraciones
    figure;
    subplot(2, 1, 1);
    hold on;
    title('');
    xlabel('Iteración');
    ylabel('Costo');
    cost_plot = plot(0, mejor_costo, 'r');

    subplot(2, 1, 2);
    hold on;
    title('');
    xlabel('Iteración');
    ylabel('Cobertura (%)');
    coverage_plot = plot(0, area_cubierta, 'b');

    iter = 0;

    while T > temp_final && area_cubierta < area_objetivo
        for i = 1:max_iter
            iter = iter + 1;
            nueva_solucion = perturbar(posiciones, polygon);
            [nuevo_costo, nueva_area_cubierta, nueva_area_interseccion, nueva_area_total_cubierta] = calcular_costo(nueva_solucion, radio_antena, polygon, area_objetivo);
            delta_E = nuevo_costo - mejor_costo;

            if delta_E < 0 || rand() < exp(-delta_E / T)
                posiciones = nueva_solucion;
                mejor_costo = nuevo_costo;
                mejor_solucion = nueva_solucion;
                area_cubierta = nueva_area_cubierta;
                area_interseccion = nueva_area_interseccion;
                area_total_cubierta = nueva_area_total_cubierta;
            end

            % Actualizar gráficos
            set(cost_plot, 'XData', [get(cost_plot, 'XData'), iter], 'YData', [get(cost_plot, 'YData'), mejor_costo]);
            set(coverage_plot, 'XData', [get(coverage_plot, 'XData'), iter], 'YData', [get(coverage_plot, 'YData'), area_cubierta]);
            drawnow;
        end
        T = T * alfa;
    end

    % Mostrar la mejor solución encontrada
    disp('Mejor solución encontrada:');
    disp(mejor_solucion);
    disp('Área cubierta de la mejor solución:');
    disp(area_cubierta);
    disp('Área de intersección de la mejor solución:');
    disp(area_interseccion);
    disp('Área total cubierta de la mejor solución:');
    disp(area_total_cubierta);

    % Visualización de la mejor solución
    figure;
    hold on;
    % Dibujar el polígono
    plot(polygon(:, 1), polygon(:, 2), 'k', 'LineWidth', 1.5);
    fill(polygon(:, 1), polygon(:, 2), 'k', 'FaceAlpha', 0.1); % Rellenar el polígono con transparencia

    % Dibujar los círculos de cobertura y las posiciones de las antenas
    for i = 1:size(mejor_solucion, 1)
        rectangle('Position', [mejor_solucion(i, 1) - radio_antena, mejor_solucion(i, 2) - radio_antena, 2 * radio_antena, 2 * radio_antena], ...
                  'Curvature', [1, 1], 'EdgeColor', 'r', 'LineWidth', 1.5);
        plot(mejor_solucion(i, 1), mejor_solucion(i, 2), 'bo', 'MarkerFaceColor', 'b');
    end

    % Añadir resultados como texto en la gráfica
    text(min(polygon(:,1)), min(polygon(:,2)) - 1000, ...
         sprintf('Área cubierta: %.2f', area_cubierta), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(min(polygon(:,1)), min(polygon(:,2)) - 2000, ...
         sprintf('Área de intersección: %.2f', area_interseccion), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(min(polygon(:,1)), min(polygon(:,2)) - 3000, ...
         sprintf('Área total cubierta: %.2f', area_total_cubierta), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

    hold off;
    axis equal;
    title('Mejor solución de cobertura de antenas');
    xlabel('X');
    ylabel('Y');
end

% Interfaz gráfica
f = figure('Position', [100, 100, 300, 200], 'MenuBar', 'none', 'Name', 'DINA-SOFT 2024', 'NumberTitle', 'off', 'Resize', 'off');

uicontrol(f, 'Style', 'text', 'Position', [20, 140, 100, 20], 'String', 'Antenas:');
edit_antenas = uicontrol(f, 'Style', 'edit', 'Position', [150, 140, 100, 20], 'String', '8');

uicontrol(f, 'Style', 'text', 'Position', [20, 100, 100, 20], 'String', 'Radio:');
edit_radio = uicontrol(f, 'Style', 'edit', 'Position', [150, 100, 100, 20], 'String', '1500');

uicontrol(f, 'Style', 'pushbutton', 'Position', [100, 40, 100, 30], 'String', 'Ejecutar', ...
          'Callback', @(src, event) ejecutar_algoritmo(str2num(get(edit_antenas, 'String')), str2num(get(edit_radio, 'String'))));

