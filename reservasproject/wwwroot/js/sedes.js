// Global State Variables
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

    fetchPlaces(); // Definido en sedes-api.js

    // Escuchar cambios en la barra de búsqueda por texto
    document.getElementById("searchInput").addEventListener("input", renderPlaces);
});

function bookUnit(unidadId, unidadNombre, SedeNombre) {
    const checkIn = document.getElementById("checkInDate").value;
    const checkOut = document.getElementById("checkOutDate").value;
    const guestsInput = document.getElementById("guestCount").value;
    const guests = guestsInput ? parseInt(guestsInput) : 1;

    const acompanantesInput = document.getElementById("acompanantesAddonInput");
    const acompanantes = acompanantesInput ? parseInt(acompanantesInput.value) : 0;

    const lavanderiaCheck = document.getElementById("lavanderiaAddonCheck");
    const lavanderia = lavanderiaCheck ? lavanderiaCheck.checked : false;

    // Redirigir a la vista de reserva con los parámetros
    window.location.href = `/Bookings/Book?unitId=${unidadId}&startDate=${checkIn}&endDate=${checkOut}&guests=${guests}&companions=${acompanantes}&laundry=${lavanderia}`;
}
