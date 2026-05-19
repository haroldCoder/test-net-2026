let allPlaces = [];
let availableUnits = [];
let isSearchingAvailability = false;
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
    // Configurar fechas mínimas por defecto
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
    
    const checkInInput = document.getElementById("checkInDate");
    const checkOutInput = document.getElementById("checkOutDate");
    
    if (checkInInput && checkOutInput) {
        checkInInput.min = today;
        checkInInput.value = today;
        checkOutInput.min = tomorrow;
        checkOutInput.value = tomorrow;

        // Actualizar mínimo de salida cuando cambie la entrada
        checkInInput.addEventListener("change", () => {
            const nextDay = new Date(new Date(checkInInput.value).getTime() + 86400000).toISOString().split('T')[0];
            checkOutInput.min = nextDay;
            if (checkOutInput.value < nextDay) {
                checkOutInput.value = nextDay;
            }
        });
    }

    fetchPlaces();

    // Escuchar cambios en la barra de búsqueda por texto
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

// Búsqueda de disponibilidad por fechas
async function searchAvailability(event) {
    event.preventDefault();

    const checkIn = document.getElementById("checkInDate").value;
    const checkOut = document.getElementById("checkOutDate").value;
    const guests = document.getElementById("guestCount").value;

    const spinner = document.getElementById("loadingSpinner");
    const grid = document.getElementById("placesGrid");

    if (!checkIn || !checkOut) {
        alert("Por favor selecciona las fechas de entrada y salida.");
        return;
    }

    grid.innerHTML = "";
    if (spinner) spinner.style.display = "block";

    try {
        let url = `/Sedes/GetAvailableSedes?fechaInicio=${checkIn}&fechaFin=${checkOut}`;
        if (guests) {
            url += `&personas=${guests}`;
        }

        const response = await fetch(url);
        if (!response.ok) throw new Error("Error en la búsqueda de disponibilidad");

        availableUnits = await response.json();
        isSearchingAvailability = true;

        // Mostrar botón de limpiar fechas
        document.getElementById("clearDatesBtn").classList.remove("d-none");

        renderPlaces();
    } catch (error) {
        console.error("Error en disponibilidad:", error);
        alert("Hubo un problema al consultar la disponibilidad. Inténtalo de nuevo.");
        isSearchingAvailability = false;
        fetchPlaces();
    }
}

function clearAvailabilitySearch() {
    isSearchingAvailability = false;
    availableUnits = [];
    
    // Ocultar botón de limpiar
    document.getElementById("clearDatesBtn").classList.add("d-none");
    
    // Resetear formulario
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
    document.getElementById("checkInDate").value = today;
    document.getElementById("checkOutDate").value = tomorrow;
    document.getElementById("guestCount").value = "";
    document.getElementById("searchInput").value = "";

    renderPlaces();
}

function filterPlaces(type, btn) {
    document.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");

    activeType = type;
    renderPlaces();
}

function renderPlaces() {
    const grid = document.getElementById("placesGrid");
    const searchVal = document.getElementById("searchInput").value.toLowerCase();
    
    grid.innerHTML = "";

    // Filtrar sedes base por categoría y búsqueda de texto
    const filteredSedes = allPlaces.filter(place => {
        const matchesType = activeType === 'todos' || place.tipo === activeType;
        const matchesSearch = place.nombre.toLowerCase().includes(searchVal) || 
                              place.ciudad.toLowerCase().includes(searchVal);
        return matchesType && matchesSearch;
    });

    if (filteredSedes.length === 0) {
        grid.innerHTML = `
            <div class="no-results">
                <i class="bi bi-search"></i>
                <h4>No encontramos resultados</h4>
                <p>Intenta buscando con palabras clave diferentes o cambia de categoría.</p>
            </div>
        `;
        return;
    }

    filteredSedes.forEach((place, index) => {
        const badgeClass = place.tipo === 'Apartamento' ? 'badge-apartamento' : 'badge-sede';
        const gradientIndex = index % backgroundGradients.length;
        const cardBg = backgroundGradients[gradientIndex];

        let availabilityBadge = '';
        let cardClass = 'place-card';
        let actionBtnText = 'Ver Detalles';
        let onClickAction = `showSedeDetails(${place.id}, '${place.nombre}')`;
        let isBtnDisabled = '';

        if (isSearchingAvailability) {
            // Filtrar unidades disponibles de esta Sede
            const unitsForSede = availableUnits.filter(u => u.sedeNombre === place.nombre);
            const count = unitsForSede.length;

            if (count > 0) {
                availabilityBadge = `<span class="status-badge status-available">🟢 ${count} Libres</span>`;
                actionBtnText = 'Ver Opciones <i class="bi bi-arrow-right"></i>';
            } else {
                availabilityBadge = `<span class="status-badge status-unavailable">🔴 Agotado</span>`;
                cardClass += ' unavailable';
                actionBtnText = 'Sin Lugares';
                isBtnDisabled = 'disabled';
                onClickAction = '';
            }
        }

        const cardHtml = `
            <div class="${cardClass}" style="animation-delay: ${index * 0.08}s">
                <div class="place-card-image" style="background: ${cardBg}">
                    ${availabilityBadge}
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
                        <span class="text-muted font-sm">
                            <i class="bi bi-shield-check text-success"></i> Verificado
                        </span>
                        <button class="place-action-btn" ${isBtnDisabled} onclick="${onClickAction}">
                            ${actionBtnText}
                        </button>
                    </div>
                </div>
            </div>
        `;
        grid.insertAdjacentHTML('beforeend', cardHtml);
    });
}

// Modal de detalles de unidades de alojamiento
function showSedeDetails(sedeId, sedeNombre) {
    const modalTitle = document.getElementById("sedeDetailsModalLabel");
    const modalBody = document.getElementById("sedeDetailsModalBody");

    modalTitle.innerHTML = `<i class="bi bi-building-geom"></i> ${sedeNombre}`;
    modalBody.innerHTML = "";

    if (!isSearchingAvailability) {
        // Si no ha buscado por fechas
        modalBody.innerHTML = `
            <div class="text-center py-4">
                <i class="bi bi-calendar-range text-primary" style="font-size: 3rem;"></i>
                <h5 class="mt-3 font-weight-bold">Consulta de Disponibilidad</h5>
                <p class="text-muted px-4">Para ver las habitaciones y cabañas libres en <strong>${sedeNombre}</strong>, por favor selecciona tus fechas de viaje en el panel superior y presiona buscar.</p>
                <button class="btn btn-primary rounded-pill px-4 mt-2" data-bs-dismiss="modal" onclick="document.getElementById('checkInDate').focus()">
                    Seleccionar Fechas
                </button>
            </div>
        `;
    } else {
        // Filtrar unidades disponibles asociadas a esta Sede
        const units = availableUnits.filter(u => u.sedeNombre === sedeNombre);

        if (units.length === 0) {
            modalBody.innerHTML = `
                <div class="text-center py-4">
                    <i class="bi bi-emoji-frown text-warning" style="font-size: 3rem;"></i>
                    <h5 class="mt-3 font-weight-bold">No hay unidades disponibles</h5>
                    <p class="text-muted px-4">Lo sentimos, no hay cabañas ni apartamentos disponibles para el rango de fechas seleccionado.</p>
                </div>
            `;
        } else {
            let listHtml = '<div class="unit-list">';
            
            units.forEach(unit => {
                const icon = unit.tipoAlojamiento.toLowerCase().includes('cabaña') ? 'bi-house-heart' : 'bi-door-closed';
                
                listHtml += `
                    <div class="unit-card">
                        <div class="unit-info-header">
                            <div class="unit-icon-wrapper">
                                <i class="bi ${icon}"></i>
                            </div>
                            <div>
                                <h4 class="unit-title">${unit.unidadNombre}</h4>
                                <div class="unit-details">
                                    <span><i class="bi bi-house"></i> ${unit.tipoAlojamiento}</span>
                                    <span><i class="bi bi-people"></i> Capacidad: ${unit.capacidadMaxima}</span>
                                    <span><i class="bi bi-door-open"></i> Alcobas: ${unit.habitacionesInternas}</span>
                                </div>
                                ${unit.detalleCamas ? `
                                <div class="mt-2 text-muted small">
                                    <i class="bi bi-info-circle text-primary"></i> Camas: ${unit.detalleCamas}
                                </div>` : ''}
                            </div>
                        </div>
                        <div>
                            <button class="btn-book-unit" onclick="bookUnit(${unit.unidadId}, '${unit.unidadNombre}', '${sedeNombre}')">
                                Reservar
                            </button>
                        </div>
                    </div>
                `;
            });

            listHtml += '</div>';
            modalBody.innerHTML = listHtml;
        }
    }

    // Mostrar el modal
    const detailsModal = new bootstrap.Modal(document.getElementById('sedeDetailsModal'));
    detailsModal.show();
}

function bookUnit(unidadId, unidadNombre, SedeNombre) {
    const checkIn = document.getElementById("checkInDate").value;
    const checkOut = document.getElementById("checkOutDate").value;
    
    alert(`¡Excelente elección!\nHas seleccionado reservar "${unidadNombre}" en la sede "${SedeNombre}" desde el ${checkIn} hasta el ${checkOut}.\n\n(En el siguiente feature implementaremos el proceso de reserva completo).`);
    
    // Opcional: Cerrar el modal
    const modalElement = document.getElementById('sedeDetailsModal');
    const modalInstance = bootstrap.Modal.getInstance(modalElement);
    if (modalInstance) {
        modalInstance.hide();
    }
}
