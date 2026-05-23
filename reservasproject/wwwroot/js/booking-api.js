let allPlaces = [];

const fetchMyBookings = async () => {
    try {
        const response = await fetch('/Bookings/GetMyBookingsData');
        if (!response.ok) throw new Error("Error en la respuesta del servidor");

        allPlaces = await response.json();
        renderPlaces();
    } catch (error) {
        console.error("Error al cargar las reservas:", error);
        document.getElementById("placesGrid").innerHTML = `
            <div class="no-results text-danger text-center w-100 py-5">
                <i class="bi bi-exclamation-triangle-fill text-danger fs-1"></i>
                <h4 class="mt-3">Error al cargar los datos</h4>
                <p>No se pudo conectar al servidor. Inténtalo de nuevo más tarde.</p>
            </div>
        `;
    }
};