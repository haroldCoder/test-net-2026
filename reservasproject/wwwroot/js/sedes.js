let allPlaces = [];
let activeType = 'todos';

// Mapeo de fondos elegantes alternativos si no se cargan imágenes
const backgroundGradients = [
    'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)',
    'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)',
    'linear-gradient(135deg, #f6d365 0%, #fda085 100%)',
    'linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%)',
    'linear-gradient(135deg, #cfd9df 0%, #e2ebf0 100%)',
    'linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%)',
    'linear-gradient(135deg, #fdcbf1 0%, #e6dee9 100%)',
    'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)'
];

document.addEventListener("DOMContentLoaded", () => {
    fetchPlaces(); // Ejecuta la función fetchPlaces al cargar la página

    // Escuchar cambios en la barra de búsqueda
    document.getElementById("searchInput").addEventListener("input", renderPlaces);
});

async function fetchPlaces() {
    try {
        const response = await fetch('/Sedes/GetSedes');
        if (!response.ok) throw new Error("Error en la respuesta del servidor");

        allPlaces = await response.json();
        renderPlaces();
    } catch (error) {
        console.error("Error al cargar las sedes:", error);
        document.getElementById("placesGrid").innerHTML = `
            <div class="no-results text-danger">
                <i class="bi bi-exclamation-triangle-fill text-danger"></i>
                <h4>Error al cargar los datos</h4>
                <p>No se pudo conectar al servidor. Inténtalo de nuevo más tarde.</p>
            </div>
        `;
    }
}

function filterPlaces(type, btn) {
    // Cambiar botón activo
    document.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");

    activeType = type;
    renderPlaces();
}

function renderPlaces() {
    const grid = document.getElementById("placesGrid");
    const searchVal = document.getElementById("searchInput").value.toLowerCase();

    grid.innerHTML = "";

    // Filtrar lugares por tipo y búsqueda
    const filtered = allPlaces.filter(place => {
        const matchesType = activeType === 'todos' || place.tipo === activeType;
        const matchesSearch = place.nombre.toLowerCase().includes(searchVal) ||
            place.ciudad.toLowerCase().includes(searchVal);
        return matchesType && matchesSearch;
    });

    if (filtered.length === 0) {
        grid.innerHTML = `
            <div class="no-results">
                <i class="bi bi-search"></i>
                <h4>No encontramos resultados</h4>
                <p>Intenta buscando con palabras clave diferentes o cambia de categoría.</p>
            </div>
        `;
        return;
    }

    filtered.forEach((place, index) => {
        const badgeClass = place.tipo === 'Apartamento' ? 'badge-apartamento' : 'badge-sede';
        const gradientIndex = index % backgroundGradients.length;
        const cardBg = backgroundGradients[gradientIndex];

        const cardHtml = `
            <div class="place-card" style="animation-delay: ${index * 0.08}s">
                <div class="place-card-image" style="background: ${cardBg}">
                    <span class="place-badge ${badgeClass}">${place.tipo}</span>
                </div>
                <div class="place-body">
                    <div>
                        <h3 class="place-title">${place.nombre}</h3>
                        <div class="place-city">
                            <i class="bi bi-geo-alt"></i> ${place.ciudad}
                        </div>
                    </div>
                    <div class="place-footer">
                        <span class="text-muted font-sm"><i class="bi bi-shield-check text-success"></i> Disponible</span>
                        <button class="place-action-btn">
                            Ver Detalles <i class="bi bi-arrow-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
        grid.insertAdjacentHTML('beforeend', cardHtml);
    });
}
