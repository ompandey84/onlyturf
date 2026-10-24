// Format date as "15 Jan 25"
export const formatDate = (dateStr) => {
    if (!dateStr) return 'Unknown Date';
    try {
        const date = new Date(dateStr);
        if (isNaN(date.getTime())) return dateStr;

        const day = date.getDate().toString().padStart(2, '0');
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const month = months[date.getMonth()];
        const year = date.getFullYear().toString().slice(-2);

        return `${day} ${month} ${year}`;
    } catch (e) {
        return dateStr;
    }
};
