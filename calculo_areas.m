% Script principal para calcular áreas y porcentajes

% Función para calcular el área de un círculo
function area = calcular_area_circulo(radio)
    area = pi * radio^2;
end

% Función para calcular el área de varios círculos
function areas = calcular_areas_circulos(radios)
    n = length(radios);
    areas = zeros(1, n);
    for i = 1:n
        areas(i) = calcular_area_circulo(radios(i));
    end
end

% Función para calcular el área de intersección de dos círculos
function area_interseccion = calcular_area_interseccion(r1, r2, d)
    if d >= r1 + r2
        area_interseccion = 0; % No hay intersección
    elseif d <= abs(r1 - r2)
        area_interseccion = pi * min(r1, r2)^2; % Un círculo está completamente dentro del otro
    else
        alpha = 2 * acos((r1^2 + d^2 - r2^2) / (2 * r1 * d));
        beta = 2 * acos((r2^2 + d^2 - r1^2) / (2 * r2 * d));
        area_interseccion = 0.5 * (r1^2 * (alpha - sin(alpha)) + r2^2 * (beta - sin(beta)));
    end
end

% Función para calcular el área de un polígono
function area = calcular_area_poligono(vertices)
    x = vertices(:, 1);
    y = vertices(:, 2);
    n = length(x);
    area = 0;
    for i = 1:n-1
        area = area + x(i) * y(i+1) - y(i) * x(i+1);
    end
    area = area + x(n) * y(1) - y(n) * x(1);
    area = abs(area) / 2;
end

% Función para calcular el porcentaje de área cubierta por los círculos dentro del polígono
function porcentaje = calcular_porcentaje_cubierto(poligono, radios, posiciones)
    areas_circulos = calcular_areas_circulos(radios);
    area_total_circulos = sum(areas_circulos);

    % Suponemos que las posiciones de los círculos son dadas en el mismo sistema de coordenadas que el polígono
    area_intersecciones = 0;
    for i = 1:length(radios)-1
        for j = i+1:length(radios)
            d = norm(posiciones(i,:) - posiciones(j,:));
            area_intersecciones = area_intersecciones + calcular_area_interseccion(radios(i), radios(j), d);
        end
    end

    area_total_circulos = area_total_circulos - area_intersecciones;
    area_poligono = calcular_area_poligono(poligono);

    porcentaje = (area_total_circulos / area_poligono) * 100;
end

% Ejemplo de uso del script
radios = [3, 4, 5];
posiciones = [1, 1; 4, 4; 7, 1]; % Coordenadas de los centros de los círculos
poligono = [0, 0; 10, 0; 10, 10; 0, 10]; % Coordenadas de los vértices del polígono

areas_circulos = calcular_areas_circulos(radios);
area_total_circulos = sum(areas_circulos);
area_intersecciones = 0;
for i = 1:length(radios)-1
    for j = i+1:length(radios)
        d = norm(posiciones(i,:) - posiciones(j,:));
        area_intersecciones = area_intersecciones + calcular_area_interseccion(radios(i), radios(j), d);
    end
end
area_total_circulos = area_total_circulos - area_intersecciones;
area_poligono = calcular_area_poligono(poligono);
porcentaje_cubierto = calcular_porcentaje_cubierto(poligono, radios, posiciones);

disp(['Área de los círculos: ', num2str(areas_circulos)]);
disp(['Área total sumada de los círculos: ', num2str(area_total_circulos)]);
disp(['Área del polígono: ', num2str(area_poligono)]);
disp(['Porcentaje cubierto por los círculos: ', num2str(porcentaje_cubierto), '%']);

